import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import '../models/transaction.dart';
import 'api_config.dart';

class TransactionsService {
  static const String mobileIdempotencySource = 'sure_mobile';

  final http.Client _client;

  TransactionsService({http.Client? client})
      : _client = client ?? http.Client();

  Future<Map<String, dynamic>> createTransaction({
    required String accessToken,
    required String accountId,
    required String name,
    required String date,
    required String amount,
    required String currency,
    required String nature,
    String? notes,
    String? categoryId,
    String? merchantId,
    List<String>? tagIds,
    String? externalId,
    String? source,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}/api/v1/transactions');
    // Idempotency is only valid when both halves of the key are present.
    final hasIdempotencyKey = externalId != null &&
        externalId.isNotEmpty &&
        source != null &&
        source.isNotEmpty;

    final body = {
      'transaction': {
        'account_id': accountId,
        'name': name,
        'date': date,
        'amount': amount,
        'currency': currency,
        'nature': nature,
        if (notes != null) 'notes': notes,
        if (categoryId != null) 'category_id': categoryId,
        if (merchantId != null) 'merchant_id': merchantId,
        if (tagIds != null) 'tag_ids': tagIds,
        if (hasIdempotencyKey) 'external_id': externalId,
        if (hasIdempotencyKey) 'source': source,
      }
    };

    try {
      final response = await _client
          .post(
            url,
            headers: {
              ...ApiConfig.getAuthHeaders(accessToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': Transaction.fromJson(responseData),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': errorMessageFromResponseBody(
            response.body,
            fallback: 'Failed to create transaction',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> getTransactions({
    required String accessToken,
    String? accountId,
    int? page,
    int? perPage,
    String? startDate,
    String? endDate,
    List<String>? categoryIds,
    bool? uncategorized,
  }) async {
    // Values are a String or, for repeated Rails array params, a List<String>.
    final Map<String, dynamic> queryParams = {};

    if (accountId != null) {
      queryParams['account_id'] = accountId;
    }
    if (page != null) {
      queryParams['page'] = page.toString();
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage.toString();
    }
    if (startDate != null) {
      queryParams['start_date'] = startDate;
    }
    if (endDate != null) {
      queryParams['end_date'] = endDate;
    }
    if (categoryIds != null && categoryIds.isNotEmpty) {
      queryParams['category_ids[]'] = categoryIds;
    }
    if (uncategorized == true) {
      queryParams['uncategorized'] = 'true';
    }

    final baseUri = Uri.parse('${ApiConfig.baseUrl}/api/v1/transactions');
    final url = queryParams.isNotEmpty
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;

    try {
      final response = await _client.get(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        // Handle both array and object responses
        List<dynamic> transactionsJson;
        Map<String, dynamic>? pagination;

        if (responseData is List) {
          transactionsJson = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('transactions')) {
          transactionsJson = responseData['transactions'];
          // Extract pagination metadata if present
          if (responseData.containsKey('pagination')) {
            pagination = responseData['pagination'];
          }
        } else {
          transactionsJson = [];
        }

        final transactions =
            transactionsJson.map((json) => Transaction.fromJson(json)).toList();

        return {
          'success': true,
          'transactions': transactions,
          if (pagination != null) 'pagination': pagination,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch transactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Every transaction in a date range (all pages, newest first), or the
  /// first page's error map.
  Future<Map<String, dynamic>> getAllTransactions({
    required String accessToken,
    required String startDate,
    required String endDate,
    String? accountId,
    int maxPages = 20,
  }) async {
    final all = <Transaction>[];
    var page = 1;
    var totalPages = 1;
    while (page <= totalPages && page <= maxPages) {
      final result = await getTransactions(
        accessToken: accessToken,
        accountId: accountId,
        startDate: startDate,
        endDate: endDate,
        page: page,
        perPage: 100,
      );
      if (result['success'] != true) return result;
      all.addAll(result['transactions'] as List<Transaction>);
      final pagination = result['pagination'];
      totalPages = pagination is Map
          ? int.tryParse(pagination['total_pages']?.toString() ?? '') ?? 1
          : 1;
      page++;
    }
    return {'success': true, 'transactions': all};
  }

  Future<Map<String, dynamic>> getTransaction({
    required String accessToken,
    required String transactionId,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/transactions/$transactionId');

    try {
      final response = await _client.get(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': Transaction.fromJson(responseData),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': errorMessageFromResponseBody(
            response.body,
            fallback: 'Failed to fetch transaction',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> updateTransaction({
    required String accessToken,
    required String transactionId,
    String? name,
    String? date,
    String? amount,
    String? currency,
    String? nature,
    String? notes,
    String? categoryId,
    String? merchantId,
    List<String>? tagIds,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/transactions/$transactionId');

    final transaction = <String, dynamic>{
      if (name != null) 'name': name,
      if (date != null) 'date': date,
      if (amount != null) 'amount': amount,
      if (currency != null) 'currency': currency,
      if (nature != null) 'nature': nature,
      if (notes != null) 'notes': notes,
      if (categoryId != null) 'category_id': categoryId,
      if (merchantId != null) 'merchant_id': merchantId,
      if (tagIds != null) 'tag_ids': tagIds,
    };

    if (transaction.isEmpty) {
      return {
        'success': false,
        'error': 'No fields to update',
      };
    }

    try {
      final response = await _client
          .patch(
            url,
            headers: {
              ...ApiConfig.getAuthHeaders(accessToken),
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'transaction': transaction}),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.body.trim().isEmpty) {
          return {
            'success': true,
            'transaction': null,
          };
        }

        final responseData = jsonDecode(response.body);
        return {
          'success': true,
          'transaction': Transaction.fromJson(responseData),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': errorMessageFromResponseBody(
            response.body,
            fallback: 'Failed to update transaction',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteTransaction({
    required String accessToken,
    required String transactionId,
  }) async {
    final url =
        Uri.parse('${ApiConfig.baseUrl}/api/v1/transactions/$transactionId');

    try {
      final response = await _client.delete(
        url,
        headers: {
          ...ApiConfig.getAuthHeaders(accessToken),
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {
          'success': true,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return {
            'success': false,
            'error': responseData['error'] ?? 'Failed to delete transaction',
          };
        } catch (e) {
          return {
            'success': false,
            'error': 'Failed to delete transaction: ${response.body}',
          };
        }
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteMultipleTransactions({
    required String accessToken,
    required List<String> transactionIds,
  }) async {
    try {
      final results = await Future.wait(
        transactionIds.map((id) => deleteTransaction(
              accessToken: accessToken,
              transactionId: id,
            )),
      );

      final allSuccess = results.every((result) => result['success'] == true);

      if (allSuccess) {
        return {
          'success': true,
          'deleted_count': transactionIds.length,
        };
      } else {
        final failedCount = results.where((r) => r['success'] != true).length;
        return {
          'success': false,
          'error': 'Failed to delete $failedCount transactions',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Uploads receipt files to a transaction (multipart `attachments[]`).
  /// On success returns the updated transaction.
  Future<Map<String, dynamic>> uploadAttachments({
    required String accessToken,
    required String transactionId,
    required List<File> files,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/transactions/$transactionId/attachments',
    );

    try {
      final boundary = 'sure-${DateTime.now().microsecondsSinceEpoch}';
      final parts = <({String name, String type, List<int> bytes})>[];
      for (final file in files) {
        parts.add((
          name: p.basename(file.path),
          type: contentTypeFor(file.path),
          bytes: await file.readAsBytes(),
        ));
      }

      final response = await _client
          .post(
            url,
            headers: {
              ...ApiConfig.getAuthHeaders(accessToken),
              'Content-Type': 'multipart/form-data; boundary=$boundary',
            },
            body: _multipartBody(boundary, parts),
          )
          .timeout(const Duration(seconds: 90));

      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'transaction': Transaction.fromJson(jsonDecode(response.body)),
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': errorMessageFromResponseBody(
            response.body,
            fallback: 'Failed to attach receipt',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  Future<Map<String, dynamic>> deleteAttachment({
    required String accessToken,
    required String transactionId,
    required String attachmentId,
  }) async {
    final url = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/transactions/$transactionId/attachments/'
      '${Uri.encodeComponent(attachmentId)}',
    );

    try {
      final response = await _client.delete(
        url,
        headers: ApiConfig.getAuthHeaders(accessToken),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 || response.statusCode == 204) {
        return {'success': true};
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': errorMessageFromResponseBody(
            response.body,
            fallback: 'Failed to remove receipt',
          ),
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// Content type from the file extension. Built by hand because http's
  /// MultipartFile needs http_parser (not a direct dependency) to set it, and
  /// the server rejects application/octet-stream.
  static String contentTypeFor(String path) {
    switch (p.extension(path).toLowerCase()) {
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.gif':
        return 'image/gif';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'image/jpeg';
    }
  }

  static Uint8List _multipartBody(
    String boundary,
    List<({String name, String type, List<int> bytes})> files,
  ) {
    final out = BytesBuilder(copy: false);
    void line(String s) => out.add(utf8.encode('$s\r\n'));
    String quoted(String s) => s
        .replaceAll('"', '%22')
        .replaceAll('\r', '')
        .replaceAll('\n', '');

    for (final file in files) {
      line('--$boundary');
      line('Content-Disposition: form-data; name="attachments[]"; '
          'filename="${quoted(file.name)}"');
      line('Content-Type: ${file.type}');
      line('');
      out.add(file.bytes);
      line('');
    }
    line('--$boundary--');
    return out.takeBytes();
  }

  static String errorMessageFromResponseBody(
    String body, {
    required String fallback,
  }) {
    try {
      final responseData = jsonDecode(body);
      if (responseData is! Map<String, dynamic>) return fallback;

      final message = responseData['message'] ?? responseData['error'];
      final errors = responseData['errors'];
      final formattedErrors = _formatErrors(errors);

      if (message != null && formattedErrors != null) {
        return '${message.toString()}: $formattedErrors';
      }

      if (formattedErrors != null) return formattedErrors;
      if (message != null) return message.toString();
    } catch (_) {
      return fallback;
    }

    return fallback;
  }

  static String? _formatErrors(dynamic errors) {
    if (errors is List) {
      final parts = errors
          .map((error) => error?.toString().trim() ?? '')
          .where((error) => error.isNotEmpty)
          .toList();
      return parts.isEmpty ? null : parts.join('; ');
    }

    if (errors is Map) {
      final parts = <String>[];
      for (final entry in errors.entries) {
        final field = _humanizeField(entry.key.toString());
        final value = entry.value;
        if (value is List) {
          for (final message in value) {
            final text = message?.toString().trim() ?? '';
            if (text.isNotEmpty) parts.add('$field $text');
          }
        } else {
          final text = value?.toString().trim() ?? '';
          if (text.isNotEmpty) parts.add('$field $text');
        }
      }
      return parts.isEmpty ? null : parts.join('; ');
    }

    return null;
  }

  static String _humanizeField(String field) {
    final words = field
        .replaceAll('_', ' ')
        .split(' ')
        .where((word) => word.isNotEmpty)
        .toList();
    if (words.isEmpty) return field;

    final first = words.first;
    words[0] = first[0].toUpperCase() + first.substring(1);
    return words.join(' ');
  }
}
