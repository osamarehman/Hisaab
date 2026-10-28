import 'package:sure_mobile/services/passkey_service.dart';

class FakeAuthenticator implements PasskeyAuthenticator {
  FakeAuthenticator({this.error});

  final Exception? error;
  Map<String, dynamic>? lastOptions;

  @override
  bool get isSupported => true;

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> options) async {
    lastOptions = options;
    if (error != null) throw error!;
    return {'id': 'new-cred', 'type': 'public-key'};
  }

  @override
  Future<Map<String, dynamic>> get(Map<String, dynamic> options) async {
    lastOptions = options;
    if (error != null) throw error!;
    return {'id': 'cred', 'type': 'public-key'};
  }
}
