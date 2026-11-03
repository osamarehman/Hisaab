import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:sure_mobile/services/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

AppUpdateInfo _info(UpdateAvailability availability) => AppUpdateInfo(
      updateAvailability: availability,
      immediateUpdateAllowed: true,
      immediateAllowedPreconditions: null,
      flexibleUpdateAllowed: true,
      flexibleAllowedPreconditions: null,
      availableVersionCode: 9,
      installStatus: InstallStatus.unknown,
      packageName: 'dev.shipdeck.hisaab',
      clientVersionStalenessDays: 1,
      updatePriority: 0,
    );

void main() {
  test('reports an update when Play has one', () async {
    final service = AppUpdateService(
        checkForUpdate: () async => _info(UpdateAvailability.updateAvailable));
    expect(await service.updateAvailable(isAndroid: true), isTrue);
  });

  test('no update when Play has none, fails, or off Android', () async {
    expect(
        await AppUpdateService(
                checkForUpdate: () async =>
                    _info(UpdateAvailability.updateNotAvailable))
            .updateAvailable(isAndroid: true),
        isFalse);
    expect(
        await AppUpdateService(
                checkForUpdate: () async => throw Exception('not from Play'))
            .updateAvailable(isAndroid: true),
        isFalse);
    var asked = false;
    expect(
        await AppUpdateService(checkForUpdate: () async {
          asked = true;
          return _info(UpdateAvailability.updateAvailable);
        }).updateAvailable(isAndroid: false),
        isFalse);
    expect(asked, isFalse);
  });

  test('opens the Play Store app, then the web page as a fallback', () async {
    final opened = <Uri>[];
    var marketWorks = true;
    final service = AppUpdateService(
      packageName: () async => 'dev.shipdeck.hisaab',
      launch: (uri, mode) async {
        opened.add(uri);
        expect(mode, LaunchMode.externalApplication);
        return uri.scheme != 'market' || marketWorks;
      },
    );

    await service.openStore();
    expect(opened.map((u) => u.toString()),
        ['market://details?id=dev.shipdeck.hisaab']);

    opened.clear();
    marketWorks = false;
    await service.openStore();
    expect(opened.map((u) => u.toString()), [
      'market://details?id=dev.shipdeck.hisaab',
      'https://play.google.com/store/apps/details?id=dev.shipdeck.hisaab',
    ]);
  });
}
