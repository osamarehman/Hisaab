import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../providers/auth_provider.dart';
import '../services/api_config.dart';
import '../services/legal_links.dart';
import '../widgets/ledger/ledger.dart';
import 'backend_config_screen.dart';
import 'sign_up_screen.dart';
import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback? onGoToSettings;

  const LoginScreen({super.key, this.onGoToSettings});

  void _openSettings(BuildContext context) {
    if (onGoToSettings != null) {
      onGoToSettings!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => BackendConfigScreen(
          onConfigSaved: () => Navigator.of(routeContext).pop(),
        ),
      ),
    );
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _otpController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;
  late final TapGestureRecognizer _signUpTapRecognizer;
  late final TapGestureRecognizer _privacyTapRecognizer;
  late final TapGestureRecognizer _termsTapRecognizer;

  @override
  void initState() {
    super.initState();
    _signUpTapRecognizer = TapGestureRecognizer()..onTap = _openSignUp;
    _privacyTapRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(context, LegalLinks.privacy);
    _termsTapRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(context, LegalLinks.terms);
  }

  @override
  void dispose() {
    _signUpTapRecognizer.dispose();
    _privacyTapRecognizer.dispose();
    _termsTapRecognizer.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _otpController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _openSignUp() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const SignUpScreen()),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final hadOtpCode =
        authProvider.showMfaInput && _otpController.text.isNotEmpty;

    final success = await authProvider.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      otpCode: authProvider.showMfaInput ? _otpController.text.trim() : null,
    );

    // Check if widget is still mounted after async operation
    if (!mounted) return;

    // Clear OTP field if login failed and user had entered an OTP code
    // This allows user to easily try again with a new code
    if (!success && hadOtpCode && authProvider.errorMessage != null) {
      _otpController.clear();
    }
  }

  Future<void> _handlePasskeyLogin() async {
    final l = AppLocalizations.of(context);
    await Provider.of<AuthProvider>(context, listen: false).loginWithPasskey(
      notFoundMessage: l.loginPasskeyNotFound,
      unsupportedMessage: l.passkeysUnsupported,
      failedMessage: l.loginPasskeyFailed,
    );
  }

  Future<void> _handleAppleLogin() async {
    final l = AppLocalizations.of(context);
    await Provider.of<AuthProvider>(context, listen: false)
        .loginWithApple(failedMessage: l.loginAppleFailed);
  }

  Widget _fieldLabel(String text, LedgerColors c) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: c.ink,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final server = Uri.tryParse(ApiConfig.baseUrl);
    final serverLabel =
        (server?.host.isNotEmpty ?? false) ? server!.host : ApiConfig.baseUrl;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 48, 20, 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l.appTitle,
                  style: LedgerText.display(
                    size: 64,
                    weight: FontWeight.w700,
                    color: c.ink,
                    letterSpacing: -2.5,
                    height: 0.9,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l.loginTagline,
                  style: TextStyle(fontSize: 17, height: 1.4, color: c.muted),
                ),
                const SizedBox(height: 32),

                // Server row.
                InkWell(
                  onTap: () => widget._openSettings(context),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: c.ink),
                        bottom: BorderSide(color: c.hairline),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l.loginServer,
                                  style:
                                      TextStyle(fontSize: 12, color: c.muted)),
                              const SizedBox(height: 2),
                              Text(
                                serverLabel,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    LedgerText.figures(size: 14, color: c.ink),
                              ),
                            ],
                          ),
                        ),
                        Text(l.loginServerChange,
                            style: TextStyle(fontSize: 13, color: c.moneyIn)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (authProvider.errorMessage == null) {
                      return const SizedBox.shrink();
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.only(left: 12),
                      decoration: BoxDecoration(
                        border: Border.all(color: c.danger),
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              authProvider.errorMessage!,
                              style: TextStyle(fontSize: 14, color: c.danger),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            tooltip: l.commonClose,
                            onPressed: () => authProvider.clearError(),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                _fieldLabel(l.loginEmailLabel, c),
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration:
                      const InputDecoration(hintText: 'you@example.com'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return l.loginEmailRequired;
                    }
                    if (!value.contains('@')) {
                      return l.loginEmailInvalid;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    final showOtp = authProvider.showMfaInput;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _fieldLabel(l.loginPasswordLabel, c),
                        TextFormField(
                          controller: _passwordController,
                          focusNode: _passwordFocus,
                          obscureText: _obscurePassword,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: showOtp
                              ? TextInputAction.next
                              : TextInputAction.done,
                          decoration: InputDecoration(
                            suffixIcon: IconButton(
                              tooltip: l.loginShowPassword,
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return l.loginPasswordRequired;
                            }
                            return null;
                          },
                          onFieldSubmitted:
                              showOtp ? null : (_) => _handleLogin(),
                        ),
                        if (showOtp) ...[
                          const SizedBox(height: 16),
                          Text(l.loginMfaInfo,
                              style: TextStyle(fontSize: 14, color: c.muted)),
                          const SizedBox(height: 12),
                          _fieldLabel(l.loginMfaLabel, c),
                          TextFormField(
                            controller: _otpController,
                            keyboardType: TextInputType.number,
                            autofillHints: const [AutofillHints.oneTimeCode],
                            textInputAction: TextInputAction.done,
                            validator: (value) {
                              if (showOtp &&
                                  (value == null || value.isEmpty)) {
                                return l.loginMfaCodeRequired;
                              }
                              return null;
                            },
                            onFieldSubmitted: (_) => _handleLogin(),
                          ),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) => ElevatedButton(
                    onPressed: authProvider.isLoading ? null : _handleLogin,
                    child: authProvider.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(l.loginSignIn),
                  ),
                ),
                const SizedBox(height: 32),

                Row(
                  children: [
                    Expanded(child: Divider(color: c.hairline)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(l.loginOrDivider,
                          style: TextStyle(fontSize: 12, color: c.muted)),
                    ),
                    Expanded(child: Divider(color: c.hairline)),
                  ],
                ),
                const SizedBox(height: 32),

                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (!authProvider.appleSignInSupported) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: OutlinedButton.icon(
                        onPressed:
                            authProvider.isLoading ? null : _handleAppleLogin,
                        icon: const Icon(Icons.apple, size: 20),
                        label: Text(l.loginSignInWithApple),
                      ),
                    );
                  },
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) => OutlinedButton.icon(
                    onPressed: authProvider.isLoading
                        ? null
                        : () => authProvider.startSsoLogin('google_oauth2'),
                    icon: SvgPicture.asset(
                      'assets/images/google_g_logo.svg',
                      width: 18,
                      height: 18,
                    ),
                    label: Text(l.loginSignInWithGoogle),
                  ),
                ),
                Consumer<AuthProvider>(
                  builder: (context, authProvider, _) {
                    if (!authProvider.passkeysSupported) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: OutlinedButton.icon(
                        onPressed:
                            authProvider.isLoading ? null : _handlePasskeyLogin,
                        icon: const Icon(Icons.fingerprint, size: 18),
                        label: Text(l.loginSignInWithPasskey),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 13, color: c.muted),
                    children: [
                      TextSpan(text: l.loginNewHere),
                      TextSpan(
                        text: l.loginCreateAccount,
                        style: TextStyle(color: c.moneyIn),
                        recognizer: _signUpTapRecognizer,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text.rich(
                  TextSpan(
                    style: TextStyle(fontSize: 12, color: c.muted),
                    children: [
                      TextSpan(
                        text: l.legalPrivacy,
                        recognizer: _privacyTapRecognizer,
                      ),
                      const TextSpan(text: '  ·  '),
                      TextSpan(
                        text: l.legalTerms,
                        recognizer: _termsTapRecognizer,
                      ),
                    ],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
