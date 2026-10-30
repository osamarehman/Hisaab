import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var passkeyChannel: PasskeyChannel?
  private var appleSignInChannel: AppleSignInChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let registrar = registrar(forPlugin: "HisaabNativeAuth") {
      passkeyChannel = PasskeyChannel(messenger: registrar.messenger())
      appleSignInChannel = AppleSignInChannel(messenger: registrar.messenger())
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
