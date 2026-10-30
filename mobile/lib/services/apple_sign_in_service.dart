import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'response_list_parser.dart';

/// Native Sign in with Apple (iOS) against `POST /api/v1/auth/apple`.
///
/// Results use the `{'success': bool, ...}` maps the other services return:
/// `body` holds the login token payload, `account_not_linked` carries the
/// linking code for SSO onboarding, and `cancelled` means the user dismissed
/// the Apple sheet.
class AppleSignInService {
  AppleSignInService({http.Client? client, MethodChannel? channel})
      : _client = client ?? http.Client(),
        _channel =
            channel ?? const MethodChannel('dev.shipdeck.hisaab/apple_sign_in');

  final http.Client _client;
  final MethodChannel _channel;

  static const _timeout = Duration(seconds: 30);

  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  Future<Map<String, dynamic>> signIn({
    required Map<String, String> deviceInfo,
  }) async {
    if (!isSupported) return {'success': false, 'unsupported': true};

    final nonce = _nonce();
    final Map<String, dynamic> credential;
    try {
      final result = await _channel
          .invokeMapMethod<String, dynamic>('signIn', {'nonce': nonce});
      if (result == null) return {'success': false, 'error': ''};
      credential = result;
    } on PlatformException catch (e) {
      if (e.code == 'cancelled') return {'success': false, 'cancelled': true};
      return {'success': false, 'error': e.message ?? ''};
    }

    try {
      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/apple'),
            headers: ApiConfig.jsonHeaders(),
            body: jsonEncode({
              'identity_token': credential['identityToken'],
              'nonce': nonce,
              if (credential['givenName'] != null)
                'first_name': credential['givenName'],
              if (credential['familyName'] != null)
                'last_name': credential['familyName'],
              'device': deviceInfo,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        return {
          'success': false,
          'status': response.statusCode,
          'error': extractErrorMessage(response.body, fallback: ''),
        };
      }

      final body = Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      if (body['status'] == 'account_not_linked') {
        return {'success': false, 'account_not_linked': true, ...body};
      }
      return {'success': true, 'body': body};
    } on TimeoutException {
      return {'success': false, 'error': 'Request timed out'};
    } catch (_) {
      return {'success': false, 'error': 'Network error'};
    }
  }

  static String _nonce() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }
}
