import 'package:flutter/foundation.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Whether Google Play has a newer build of the app for this user, and a way
/// to open the app's Play Store page.
///
/// Uses Play's in-app update API rather than the public store page, so it
/// also sees releases on the testing tracks the user has joined. It only
/// answers for installs that came from Play; anything else reports no update.
class AppUpdateService {
  AppUpdateService({
    Future<AppUpdateInfo> Function()? checkForUpdate,
    Future<bool> Function(Uri uri, LaunchMode mode)? launch,
    Future<String> Function()? packageName,
  })  : _checkForUpdate = checkForUpdate ?? InAppUpdate.checkForUpdate,
        _launch = launch ?? ((uri, mode) => launchUrl(uri, mode: mode)),
        _packageName = packageName ??
            (() async => (await PackageInfo.fromPlatform()).packageName);

  final Future<AppUpdateInfo> Function() _checkForUpdate;
  final Future<bool> Function(Uri uri, LaunchMode mode) _launch;
  final Future<String> Function() _packageName;

  /// True when Play offers a newer version. False off Android, offline, or
  /// for installs that didn't come from Play.
  Future<bool> updateAvailable({bool? isAndroid}) async {
    final android = isAndroid ??
        (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);
    if (!android) return false;
    try {
      final info = await _checkForUpdate();
      return info.updateAvailability == UpdateAvailability.updateAvailable;
    } catch (_) {
      return false;
    }
  }

  /// Opens the app's page in the Play Store app, or in the browser when the
  /// Play Store app isn't there.
  Future<void> openStore() async {
    final id = await _packageName();
    final opened = await _tryLaunch(
        Uri.parse('market://details?id=$id'), LaunchMode.externalApplication);
    if (!opened) {
      await _tryLaunch(
          Uri.parse('https://play.google.com/store/apps/details?id=$id'),
          LaunchMode.externalApplication);
    }
  }

  Future<bool> _tryLaunch(Uri uri, LaunchMode mode) async {
    try {
      return await _launch(uri, mode);
    } catch (_) {
      return false;
    }
  }
}
