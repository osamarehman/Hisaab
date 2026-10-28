import WebauthnController from "controllers/webauthn_controller";
import {
  prepareCredentialCreationOptions,
  serializePublicKeyCredential,
} from "utils/webauthn";

export default class extends WebauthnController {
  static targets = ["error", "nickname", "code", "password"];
  static values = {
    optionsUrl: String,
    createUrl: String,
    unsupportedMessage: String,
    errorFallback: String,
  };

  async register(event) {
    event.preventDefault();
    this.clearError();

    if (!window.PublicKeyCredential) {
      this.showError(this.unsupportedMessageValue);
      return;
    }

    try {
      const options = await this.fetchOptions();
      const credential = await navigator.credentials.create({
        publicKey: prepareCredentialCreationOptions(options),
      });

      await this.createCredential(serializePublicKeyCredential(credential));
    } catch (error) {
      this.showError(error.message);
    }
  }

  async fetchOptions() {
    const response = await fetch(this.optionsUrlValue, {
      method: "POST",
      headers: this.headers,
      credentials: "same-origin",
      body: JSON.stringify({
        webauthn_credential: this.stepUp,
      }),
    });

    if (!response.ok) throw new Error(await this.errorMessage(response));

    return response.json();
  }

  // The MFA code when two-factor is on, otherwise the account password.
  get stepUp() {
    return {
      code: this.hasCodeTarget ? this.codeTarget.value : "",
      password: this.hasPasswordTarget ? this.passwordTarget.value : "",
    };
  }

  async createCredential(credential) {
    const response = await fetch(this.createUrlValue, {
      method: "POST",
      headers: this.headers,
      credentials: "same-origin",
      body: JSON.stringify({
        credential,
        webauthn_credential: {
          nickname: this.hasNicknameTarget ? this.nicknameTarget.value : "",
          ...this.stepUp,
        },
      }),
    });

    if (!response.ok) throw new Error(await this.errorMessage(response));

    const result = await response.json();
    window.location.href = result.redirect_url;
  }
}
