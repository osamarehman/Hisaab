import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../models/import_job.dart';
import 'api_config.dart';
import 'response_list_parser.dart';

/// Statement imports. PDFs go up as `PdfImport` (server extracts lines with
/// AI); CSVs as `TransactionImport`. See docs/redesign/household-api.md.
class ImportsService {
  ImportsService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  /// Import type and MIME type for a statement file, or null if unsupported.
  static ({String type, String mime})? fileKind(String fileName) {
    final name = fileName.toLowerCase();
    if (name.endsWith('.pdf')) {
      return (type: 'PdfImport', mime: 'application/pdf');
    }
    if (name.endsWith('.csv')) {
      return (type: 'TransactionImport', mime: 'text/csv');
    }
    return null;
  }

  Future<Map<String, dynamic>> listImports({
    required String accessToken,
    int perPage = 10,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/imports')
          .replace(queryParameters: {'page': '1', 'per_page': '$perPage'});
      final response = await _client
          .get(url, headers: ApiConfig.getAuthHeaders(accessToken))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final imports =
            extractJsonObjectList(jsonDecode(response.body), key: 'data')
                .map(ImportJob.fromJson)
                .toList();
        return {'success': true, 'imports': imports};
      }
      return _failure(response, 'Failed to load statements');
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  Future<Map<String, dynamic>> getImport({
    required String accessToken,
    required String importId,
  }) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/imports/$importId'),
            headers: ApiConfig.getAuthHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        return {'success': true, 'import': _parse(response.body)};
      }
      return _failure(response, 'Failed to load statement');
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Uploads a statement file for [accountId].
  Future<Map<String, dynamic>> uploadStatement({
    required String accessToken,
    required String accountId,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final kind = fileKind(fileName);
    if (kind == null) {
      return {'success': false, 'error': 'Choose a PDF or CSV file.'};
    }
    final boundary = 'sure-${Random().nextInt(1 << 32)}'
        '${DateTime.now().microsecondsSinceEpoch}';
    final request = http.Request(
      'POST',
      Uri.parse('${ApiConfig.baseUrl}/api/v1/imports'),
    )
      ..headers.addAll(ApiConfig.getAuthHeaders(accessToken))
      ..headers['Content-Type'] = 'multipart/form-data; boundary=$boundary'
      ..bodyBytes = buildMultipartBody(
        boundary: boundary,
        fields: {'type': kind.type, 'account_id': accountId},
        fileField: 'file',
        fileName: fileName,
        fileContentType: kind.mime,
        fileBytes: bytes,
      );

    try {
      final streamed =
          await _client.send(request).timeout(const Duration(seconds: 120));
      final response = await http.Response.fromStream(streamed);
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 202) {
        return {
          'success': true,
          'import': _parse(response.body).copyWith(fileName: fileName),
        };
      }
      return _failure(response, 'Could not upload the statement');
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// Creates the transactions of a pending import (rules run afterwards).
  Future<Map<String, dynamic>> publishImport({
    required String accessToken,
    required String importId,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/imports/$importId/publish'),
            headers: ApiConfig.getAuthHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 200 || response.statusCode == 202) {
        return {'success': true, 'import': _parse(response.body)};
      }
      return _failure(response, 'Could not add the statement lines');
    } catch (e) {
      return {'success': false, 'error': 'Network error: $e'};
    }
  }

  /// multipart/form-data body built by hand: http's MultipartFile needs
  /// http_parser's MediaType for the part content type, and Rails rejects
  /// statements sent as application/octet-stream.
  static Uint8List buildMultipartBody({
    required String boundary,
    required Map<String, String> fields,
    required String fileField,
    required String fileName,
    required String fileContentType,
    required List<int> fileBytes,
  }) {
    final out = BytesBuilder(copy: false);
    void line(String s) => out.add(utf8.encode('$s\r\n'));
    String quoted(String s) =>
        s.replaceAll('"', '%22').replaceAll('\r', '').replaceAll('\n', '');

    fields.forEach((name, value) {
      line('--$boundary');
      line('Content-Disposition: form-data; name="${quoted(name)}"');
      line('');
      line(value);
    });
    line('--$boundary');
    line('Content-Disposition: form-data; name="${quoted(fileField)}"; '
        'filename="${quoted(fileName)}"');
    line('Content-Type: $fileContentType');
    line('');
    out.add(fileBytes);
    out.add(utf8.encode('\r\n--$boundary--\r\n'));
    return out.takeBytes();
  }

  ImportJob _parse(String body) {
    final decoded = jsonDecode(body);
    return ImportJob.fromJson(
      decoded is Map ? Map<String, dynamic>.from(decoded) : const {},
    );
  }

  Map<String, dynamic> _failure(http.Response response, String fallback) {
    if (response.statusCode == 401) {
      return {'success': false, 'error': 'unauthorized'};
    }
    return {
      'success': false,
      'error': extractErrorMessage(response.body, fallback: fallback),
    };
  }
}
