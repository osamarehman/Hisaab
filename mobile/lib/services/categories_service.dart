import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import 'api_config.dart';
import 'response_list_parser.dart';

class CategoriesService {
  CategoriesService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<Map<String, dynamic>> getCategories({
    required String accessToken,
    int? page,
    int? perPage,
    bool? rootsOnly,
    String? parentId,
  }) async {
    final Map<String, String> queryParams = {};

    if (page != null) {
      queryParams['page'] = page.toString();
    }
    if (perPage != null) {
      queryParams['per_page'] = perPage.toString();
    }
    if (rootsOnly == true) {
      queryParams['roots_only'] = 'true';
    }
    if (parentId != null) {
      queryParams['parent_id'] = parentId;
    }

    final baseUri = Uri.parse('${ApiConfig.baseUrl}/api/v1/categories');
    final url = queryParams.isNotEmpty
        ? baseUri.replace(queryParameters: queryParams)
        : baseUri;

    try {
      final response = await _client
          .get(url, headers: ApiConfig.getJsonAuthHeaders(accessToken))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        List<dynamic> categoriesJson;
        if (responseData is List) {
          categoriesJson = responseData;
        } else if (responseData is Map &&
            responseData.containsKey('categories')) {
          categoriesJson = responseData['categories'];
        } else {
          categoriesJson = [];
        }

        final categories =
            categoriesJson.map((json) => Category.fromJson(json)).toList();

        return {
          'success': true,
          'categories': categories,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'error': 'unauthorized',
        };
      } else {
        return {
          'success': false,
          'error': 'Failed to fetch categories',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'error': 'Network error: ${e.toString()}',
      };
    }
  }

  /// `POST /api/v1/categories`. Icon is chosen by the server when omitted.
  Future<Map<String, dynamic>> createCategory({
    required String accessToken,
    required String name,
    required String color,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'POST',
      path: '/api/v1/categories',
      body: {'name': name, 'color': color},
      fallback: 'Could not create the label',
    );
  }

  /// `PATCH /api/v1/categories/:id`.
  Future<Map<String, dynamic>> updateCategory({
    required String accessToken,
    required String categoryId,
    String? name,
    String? color,
  }) {
    return _write(
      accessToken: accessToken,
      method: 'PATCH',
      path: '/api/v1/categories/$categoryId',
      body: {
        if (name != null) 'name': name,
        if (color != null) 'color': color,
      },
      fallback: 'Could not save the label',
    );
  }

  /// `DELETE /api/v1/categories/:id`; its transactions become unlabelled.
  Future<Map<String, dynamic>> deleteCategory({
    required String accessToken,
    required String categoryId,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/categories/$categoryId'),
            headers: ApiConfig.getAuthHeaders(accessToken),
          )
          .timeout(const Duration(seconds: 30));
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {
        'success': false,
        'error': extractErrorMessage(response.body,
            fallback: 'Could not delete the label'),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }

  Future<Map<String, dynamic>> _write({
    required String accessToken,
    required String method,
    required String path,
    required Map<String, dynamic> body,
    required String fallback,
  }) async {
    try {
      final request =
          http.Request(method, Uri.parse('${ApiConfig.baseUrl}$path'))
            ..headers.addAll(ApiConfig.getJsonAuthHeaders(accessToken))
            ..body = jsonEncode({'category': body});
      final response = await http.Response.fromStream(
        await _client.send(request).timeout(const Duration(seconds: 30)),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'category': Category.fromJson(Map<String, dynamic>.from(json as Map)),
        };
      }
      if (response.statusCode == 401) {
        return {'success': false, 'error': 'unauthorized'};
      }
      return {
        'success': false,
        'error': extractErrorMessage(response.body, fallback: fallback),
      };
    } catch (e) {
      return {'success': false, 'error': 'Network error: ${e.toString()}'};
    }
  }
}
