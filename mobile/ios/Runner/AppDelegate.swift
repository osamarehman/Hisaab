import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var passkeyChannel: PasskeyChannel?
  private var appleSignInChannel: AppleSignInChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "HisaabNativeAuth") {
      passkeyChannel = PasskeyChannel(messenger: registrar.messenger())
      appleSignInChannel = AppleSignInChannel(messenger: registrar.messenger())
    }
  }
}
