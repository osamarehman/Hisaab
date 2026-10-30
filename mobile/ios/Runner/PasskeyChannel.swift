import AuthenticationServices
import Flutter
import UIKit

/// Platform passkeys (iCloud Keychain and other providers) for the Dart
/// `IosPasskeyAuthenticator`. Takes and returns WebAuthn JSON with base64url
/// binary fields, the shape the server's `/passkey` endpoints use.
///
/// Errors: `cancelled`, `not_found`, `unsupported`, `invalid_options`,
/// `failed`.
final class PasskeyChannel: NSObject {
  static let name = "dev.shipdeck.hisaab/passkeys"

  private let channel: FlutterMethodChannel
  private var pending: PasskeyRequest?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: PasskeyChannel.name, binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      self?.handle(call, result: result)
    }
  }

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard pending == nil else {
      result(FlutterError(code: "failed", message: "A passkey request is already in progress", details: nil))
      return
    }
    guard let options = call.arguments as? [String: Any] else {
      result(FlutterError(code: "invalid_options", message: "Missing WebAuthn options", details: nil))
      return
    }

    let request: ASAuthorizationRequest
    do {
      switch call.method {
      case "create": request = try Self.registrationRequest(options)
      case "get": request = try Self.assertionRequest(options)
      default:
        result(FlutterMethodNotImplemented)
        return
      }
    } catch {
      result(FlutterError(code: "invalid_options", message: "\(error)", details: nil))
      return
    }

    let passkeyRequest = PasskeyRequest(request: request) { [weak self] outcome in
      self?.pending = nil
      result(outcome)
    }
    pending = passkeyRequest
    passkeyRequest.start()
  }

  private static func provider(_ options: [String: Any], rpId: String?) throws -> ASAuthorizationPlatformPublicKeyCredentialProvider {
    guard let rpId, !rpId.isEmpty else { throw PasskeyOptionsError.missing("rp id") }
    return ASAuthorizationPlatformPublicKeyCredentialProvider(relyingPartyIdentifier: rpId)
  }

  private static func registrationRequest(_ options: [String: Any]) throws -> ASAuthorizationRequest {
    let rp = options["rp"] as? [String: Any]
    let user = options["user"] as? [String: Any] ?? [:]
    guard let challenge = Base64URL.decode(options["challenge"] as? String) else {
      throw PasskeyOptionsError.missing("challenge")
    }
    guard let userId = Base64URL.decode(user["id"] as? String) else {
      throw PasskeyOptionsError.missing("user.id")
    }
    let name = (user["name"] as? String) ?? (user["displayName"] as? String) ?? ""

    let request = try provider(options, rpId: rp?["id"] as? String)
      .createCredentialRegistrationRequest(challenge: challenge, name: name, userID: userId)

    if let selection = options["authenticatorSelection"] as? [String: Any],
       let verification = selection["userVerification"] as? String {
      request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: verification)
    }
    if #available(iOS 17.4, *) {
      request.excludedCredentials = descriptors(options["excludeCredentials"])
    }
    return request
  }

  private static func assertionRequest(_ options: [String: Any]) throws -> ASAuthorizationRequest {
    guard let challenge = Base64URL.decode(options["challenge"] as? String) else {
      throw PasskeyOptionsError.missing("challenge")
    }
    let request = try provider(options, rpId: options["rpId"] as? String)
      .createCredentialAssertionRequest(challenge: challenge)
    request.allowedCredentials = descriptors(options["allowCredentials"])
    if let verification = options["userVerification"] as? String {
      request.userVerificationPreference = ASAuthorizationPublicKeyCredentialUserVerificationPreference(rawValue: verification)
    }
    return request
  }

  private static func descriptors(_ value: Any?) -> [ASAuthorizationPlatformPublicKeyCredentialDescriptor] {
    (value as? [[String: Any]] ?? []).compactMap { entry in
      Base64URL.decode(entry["id"] as? String).map {
        ASAuthorizationPlatformPublicKeyCredentialDescriptor(credentialID: $0)
      }
    }
  }
}

private enum PasskeyOptionsError: Error, CustomStringConvertible {
  case missing(String)

  var description: String {
    switch self {
    case .missing(let field): return "WebAuthn options are missing \(field)"
    }
  }
}

/// One system passkey sheet. Kept alive by `PasskeyChannel.pending` until the
/// delegate reports back.
private final class PasskeyRequest: NSObject, ASAuthorizationControllerDelegate,
  ASAuthorizationControllerPresentationContextProviding
{
  private let controller: ASAuthorizationController
  private let completion: (Any?) -> Void

  init(request: ASAuthorizationRequest, completion: @escaping (Any?) -> Void) {
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
    switch authorization.credential {
    case let credential as ASAuthorizationPlatformPublicKeyCredentialRegistration:
      guard let attestation = credential.rawAttestationObject else {
        completion(FlutterError(code: "failed", message: "The passkey provider returned no attestation", details: nil))
        return
      }
      let id = Base64URL.encode(credential.credentialID)
      completion([
        "id": id,
        "rawId": id,
        "type": "public-key",
        "authenticatorAttachment": "platform",
        "clientExtensionResults": [String: Any](),
        "response": [
          "clientDataJSON": Base64URL.encode(credential.rawClientDataJSON),
          "attestationObject": Base64URL.encode(attestation),
          "transports": ["internal", "hybrid"],
        ],
      ])
    case let credential as ASAuthorizationPlatformPublicKeyCredentialAssertion:
      let id = Base64URL.encode(credential.credentialID)
      completion([
        "id": id,
        "rawId": id,
        "type": "public-key",
        "authenticatorAttachment": "platform",
        "clientExtensionResults": [String: Any](),
        "response": [
          "clientDataJSON": Base64URL.encode(credential.rawClientDataJSON),
          "authenticatorData": Base64URL.encode(credential.rawAuthenticatorData),
          "signature": Base64URL.encode(credential.signature),
          "userHandle": Base64URL.encode(credential.userID),
        ],
      ])
    default:
      completion(FlutterError(code: "failed", message: "Unexpected credential type", details: nil))
    }
  }

  func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
    let code: String
    switch (error as? ASAuthorizationError)?.code {
    case .canceled: code = "cancelled"
    case .notInteractive: code = "not_found"
    default: code = "failed"
    }
    completion(FlutterError(code: code, message: error.localizedDescription, details: nil))
  }
}

enum Base64URL {
  static func encode(_ data: Data) -> String {
    data.base64EncodedString()
      .replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
      .replacingOccurrences(of: "=", with: "")
  }

  static func decode(_ string: String?) -> Data? {
    guard var value = string, !value.isEmpty else { return nil }
    value = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    value += String(repeating: "=", count: (4 - value.count % 4) % 4)
    return Data(base64Encoded: value)
  }
}
