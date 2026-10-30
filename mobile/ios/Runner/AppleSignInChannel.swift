import AuthenticationServices
import CryptoKit
import Flutter
import UIKit

/// Native Sign in with Apple for the Dart `AppleSignInService`. Apple receives
/// the SHA-256 of the caller's nonce; the server checks the raw nonce against
/// the token's `nonce` claim.
///
/// Errors: `cancelled`, `invalid_arguments`, `failed`.
final class AppleSignInChannel: NSObject {
  static let name = "dev.shipdeck.hisaab/apple_sign_in"

  private let channel: FlutterMethodChannel
  private var pending: AppleSignInRequest?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: AppleSignInChannel.name, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "signIn" else {
      result(FlutterMethodNotImplemented)
      return
    }
    guard pending == nil else {
      result(FlutterError(code: "failed", message: "Sign in with Apple is already in progress", details: nil))
      return
    }
    guard let nonce = (call.arguments as? [String: Any])?["nonce"] as? String, !nonce.isEmpty else {
      result(FlutterError(code: "invalid_arguments", message: "Missing nonce", details: nil))
      return
    }

    let request = ASAuthorizationAppleIDProvider().createRequest()
    request.requestedScopes = [.fullName, .email]
    request.nonce = SHA256.hash(data: Data(nonce.utf8)).map { String(format: "%02x", $0) }.joined()

    let appleRequest = AppleSignInRequest(request: request) { [weak self] outcome in
      self?.pending = nil
      result(outcome)
    }
    pending = appleRequest
    appleRequest.start()
  }
}

private final class AppleSignInRequest: NSObject, ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding
{
  private let controller: ASAuthorizationController
  private let completion: (Any?) -> Void

  init(request: ASAuthorizationAppleIDRequest, completion: @escaping (Any?) -> Void) {
    controller = ASAuthorizationController(authorizationRequests: [request])
    self.completion = completion
    super.init()
    controller.delegate = self
    controller.presentationContextProvider = self
  }

  func start() {
    controller.performRequests()
  }

  func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
    let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
    guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential,
          let tokenData = credential.identityToken,
          let token = String(data: tokenData, encoding: .utf8)
    else {
      completion(FlutterError(code: "failed", message: "Apple returned no identity token", details: nil))
      return
    }

    // Name and email are only present the first time the user signs in.
    var payload: [String: Any] = ["identityToken": token]
    if let given = credential.fullName?.givenName { payload["givenName"] = given }
    if let family = credential.fullName?.familyName { payload["familyName"] = family }
    completion(payload)
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    let code = (error as? ASAuthorizationError)?.code == .canceled ? "cancelled" : "failed"
    completion(FlutterError(code: code, message: error.localizedDescription, details: nil))
  }
}
