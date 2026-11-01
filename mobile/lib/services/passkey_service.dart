import 'dart:async';
import 'dart:convert';

import 'package:credential_manager/credential_manager.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'response_list_parser.dart';

/// The user dismissed the system passkey sheet.
class PasskeyCancelledException implements Exception {}

/// The device has no passkey for this server.
class PasskeyNotFoundException implements Exception {}

/// The device cannot create or use passkeys.
class PasskeyUnsupportedException implements Exception {}

/// Seam over the platform passkey prompt so the API flow can be tested.
/// Options and results are WebAuthn JSON (base64url binary fields).
abstract class PasskeyAuthenticator {
  bool get isSupported;

  Future<Map<String, dynamic>> create(Map<String, dynamic> options);

  Future<Map<String, dynamic>> get(Map<String, dynamic> options);
}

/// Android Credential Manager (Google Password Manager and other providers).
class CredentialManagerPasskeyAuthenticator implements PasskeyAuthenticator {
  CredentialManagerPasskeyAuthenticator();

  final CredentialManager _manager = CredentialManager();
  Future<void>? _ready;

  @override
  bool get isSupported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> _init() => _ready ??= _manager
      .init(preferImmediatelyAvailableCredentials: false)
      .catchError((Object e) {
        _ready = null;
        throw e;
      });

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> options) async {
    if (!isSupported) throw PasskeyUnsupportedException();
    try {
      await _init();
      final credential = await _manager.savePasskeyCredentials(
        request: CredentialCreationOptions.fromJson(options),
      );
      return _withoutNulls(credential.toJson());
    } on CredentialException catch (e) {
      throw _mapException(e);
    }
  }

  @override
  Future<Map<String, dynamic>> get(Map<String, dynamic> options) async {
    if (!isSupported) throw PasskeyUnsupportedException();
    try {
      await _init();
      final credentials = await _manager.getCredentials(
        passKeyOption: CredentialLoginOptions.fromJson(options),
        fetchOptions: FetchOptionsAndroid(passKey: true),
      );
      final credential = credentials.publicKeyCredential;
      if (credential == null) throw PasskeyNotFoundException();
      return _withoutNulls(credential.toJson());
    } on CredentialException catch (e) {
      throw _mapException(e);
    }
  }

  Exception _mapException(CredentialException e) {
    switch (e.code) {
      case 201:
      case 301:
      case 601:
        return PasskeyCancelledException();
      case 202:
        return PasskeyNotFoundException();
      case 209:
        return PasskeyUnsupportedException();
      case 603:
        // The plugin reports old Android versions as a fetch failure.
        return (e.details?.toString().contains('Android version') ?? false)
            ? PasskeyUnsupportedException()
            : e;
      default:
        return e;
    }
  }
}

/// iOS platform passkeys through `PasskeyChannel.swift` (AuthenticationServices).
class IosPasskeyAuthenticator implements PasskeyAuthenticator {
  IosPasskeyAuthenticator({MethodChannel? channel})
      : _channel =
            channel ?? const MethodChannel('dev.shipdeck.hisaab/passkeys');

  final MethodChannel _channel;

  @override
  bool get isSupported => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> options) =>
      _invoke('create', options);

  @override
  Future<Map<String, dynamic>> get(Map<String, dynamic> options) =>
      _invoke('get', options);

  Future<Map<String, dynamic>> _invoke(
      String method, Map<String, dynamic> options) async {
    if (!isSupported) throw PasskeyUnsupportedException();
    try {
      final result = await _channel.invokeMapMethod<String, dynamic>(
          method, _jsonSafe(options));
      if (result == null) throw PasskeyNotFoundException();
      return _deepStringKeys(result);
    } on PlatformException catch (e) {
      switch (e.code) {
        case 'cancelled':
          throw PasskeyCancelledException();
        case 'not_found':
          throw PasskeyNotFoundException();
        case 'unsupported':
          throw PasskeyUnsupportedException();
        default:
          rethrow;
      }
    }
  }

  /// Round-trips through JSON so only plain maps, lists and scalars reach the
  /// platform channel codec.
  static Map<String, dynamic> _jsonSafe(Map<String, dynamic> options) =>
      Map<String, dynamic>.from(jsonDecode(jsonEncode(options)) as Map);

  static Map<String, dynamic> _deepStringKeys(Map<dynamic, dynamic> map) =>
      map.map((key, value) => MapEntry(
            key.toString(),
            value is Map ? _deepStringKeys(value) : value,
          ));
}

/// The passkey authenticator for the platform the app is running on.
PasskeyAuthenticator platformPasskeyAuthenticator() =>
    !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS
        ? IosPasskeyAuthenticator()
        : CredentialManagerPasskeyAuthenticator();

/// Drops null fields, which the plugin fills in for parts of the WebAuthn
/// response a ceremony does not produce.
Map<String, dynamic> _withoutNulls(Map<String, dynamic> json) {
  final result = <String, dynamic>{};
  json.forEach((key, value) {
    if (value == null) return;
    result[key] = value is Map<String, dynamic> ? _withoutNulls(value) : value;
  });
  return result;
}

class Passkey {
  const Passkey({
    required this.id,
    required this.nickname,
    required this.createdAt,
    this.lastUsedAt,
  });

  final String id;
  final String nickname;
  final DateTime? createdAt;
  final DateTime? lastUsedAt;

  factory Passkey.fromJson(Map<String, dynamic> json) => Passkey(
        id: json['id']?.toString() ?? '',
        nickname: json['nickname']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        lastUsedAt: DateTime.tryParse(json['last_used_at']?.toString() ?? ''),
      );
}

/// What adding a passkey asks for to confirm it's the account owner.
enum PasskeyStepUp { code, password, unavailable }

/// Passkey sign-in and management against `/api/v1/auth/passkey/*` and
/// `/api/v1/passkeys`. Results use the `{'success': bool, ...}` maps the other
/// services return; cancellation is reported as `'cancelled': true`.
class PasskeyService {
  PasskeyService({http.Client? client, PasskeyAuthenticator? authenticator})
      : _client = client ?? http.Client(),
        authenticator = authenticator ?? platformPasskeyAuthenticator();

  final http.Client _client;
  final PasskeyAuthenticator authenticator;

  static const _timeout = Duration(seconds: 30);

  bool get isSupported => authenticator.isSupported;

  /// Signs in with a passkey. On success `body` holds the same token payload
  /// as `POST /api/v1/auth/login`.
  Future<Map<String, dynamic>> signIn({
    required Map<String, String> deviceInfo,
  }) async {
    try {
      final optionsResponse = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/passkey/options'),
            headers: ApiConfig.jsonHeaders(),
          )
          .timeout(_timeout);
      if (optionsResponse.statusCode != 200) {
        return _failure(optionsResponse);
      }
      final options =
          Map<String, dynamic>.from(jsonDecode(optionsResponse.body) as Map);

      final assertion = await authenticator.get(options);

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/auth/passkey/login'),
            headers: ApiConfig.jsonHeaders(),
            body: jsonEncode({
              'challenge': options['challenge'],
              'credential': assertion,
              'device': deviceInfo,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return _failure(response);

      return {
        'success': true,
        'body': Map<String, dynamic>.from(jsonDecode(response.body) as Map),
      };
    } on PasskeyCancelledException {
      return {'success': false, 'cancelled': true};
    } on PasskeyNotFoundException {
      return {'success': false, 'not_found': true};
    } on PasskeyUnsupportedException {
      return {'success': false, 'unsupported': true};
    } catch (e) {
      return {'success': false, 'error': _describe(e)};
    }
  }

  Future<Map<String, dynamic>> list({required String accessToken}) async {
    try {
      final response = await _client
          .get(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/passkeys'),
            headers: ApiConfig.getJsonAuthHeaders(accessToken),
          )
          .timeout(_timeout);
      if (response.statusCode != 200) return _failure(response);

      final body = jsonDecode(response.body) as Map;
      final passkeys = (body['passkeys'] as List? ?? const [])
          .whereType<Map>()
          .map((json) => Passkey.fromJson(Map<String, dynamic>.from(json)))
          .toList();
      final stepUp = switch (body['step_up']) {
        'code' => PasskeyStepUp.code,
        'password' => PasskeyStepUp.password,
        _ => PasskeyStepUp.unavailable,
      };
      return {'success': true, 'passkeys': passkeys, 'step_up': stepUp};
    } catch (e) {
      return {'success': false, 'error': _describe(e)};
    }
  }

  /// Creates a passkey on the device and saves it on the server. [code] or
  /// [password] is the step-up the server asked for in [list].
  Future<Map<String, dynamic>> add({
    required String accessToken,
    required String nickname,
    String? code,
    String? password,
  }) async {
    final stepUp = {
      if (code != null) 'code': code,
      if (password != null) 'password': password,
    };
    try {
      final optionsResponse = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/passkeys/options'),
            headers: ApiConfig.getJsonAuthHeaders(accessToken),
            body: jsonEncode(stepUp),
          )
          .timeout(_timeout);
      if (optionsResponse.statusCode != 200) return _failure(optionsResponse);
      final options =
          Map<String, dynamic>.from(jsonDecode(optionsResponse.body) as Map);

      final credential = await authenticator.create(options);

      final response = await _client
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/passkeys'),
            headers: ApiConfig.getJsonAuthHeaders(accessToken),
            body: jsonEncode({
              ...stepUp,
              'challenge': options['challenge'],
              'credential': credential,
              'nickname': nickname,
            }),
          )
          .timeout(_timeout);
      if (response.statusCode != 201) return _failure(response);

      return {
        'success': true,
        'passkey': Passkey.fromJson(
            Map<String, dynamic>.from(jsonDecode(response.body) as Map)),
      };
    } on PasskeyCancelledException {
      return {'success': false, 'cancelled': true};
    } on PasskeyUnsupportedException {
      return {'success': false, 'unsupported': true};
    } catch (e) {
      return {'success': false, 'error': _describe(e)};
    }
  }

  Future<Map<String, dynamic>> remove({
    required String accessToken,
    required String id,
  }) async {
    try {
      final response = await _client
          .delete(
            Uri.parse('${ApiConfig.baseUrl}/api/v1/passkeys/$id'),
            headers: ApiConfig.getJsonAuthHeaders(accessToken),
          )
          .timeout(_timeout);
      if (response.statusCode == 204 || response.statusCode == 200) {
        return {'success': true};
      }
      return _failure(response);
    } catch (e) {
      return {'success': false, 'error': _describe(e)};
    }
  }

  Map<String, dynamic> _failure(http.Response response) => {
        'success': false,
        'status': response.statusCode,
        'error': extractErrorMessage(response.body, fallback: ''),
      };

  String _describe(Object error) {
    if (error is TimeoutException) return 'Request timed out';
    if (error is CredentialException) return error.message;
    if (error is PlatformException) return error.message ?? error.code;
    return 'Network error';
  }
}
