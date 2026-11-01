import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/legal_links.dart';
import '../widgets/ledger/ledger.dart';

/// Creates an account on the configured server through `POST /auth/signup`.
/// On success the provider holds the new session and the app's root swaps the
/// login screen for home, so this route pops itself.
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  late final TapGestureRecognizer _termsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;
  bool _obscurePassword = true;

  // Mirrors the server's signup password rules so mistakes show before submit.
  static final _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');

  @override
  void initState() {
    super.initState();
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(context, LegalLinks.terms);
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => LegalLinks.open(context, LegalLinks.privacy);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<AuthProvider>().clearError();
    });
  }

  @override
  void dispose() {
    _termsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value, AppLocalizations l) {
    final password = value ?? '';
    final strong = password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'\d').hasMatch(password) &&
        _special.hasMatch(password);
    return strong ? null : l.signUpPasswordRules;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final success = await auth.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      firstName: _firstNameController.text.trim(),
      lastName: _lastNameController.text.trim(),
    );

    if (success && mounted) Navigator.of(context).pop();
  }

  Widget _label(String text, LedgerColors c) => Padding(
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

    return Scaffold(
      appBar: AppBar(title: Text(l.signUpTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: AutofillGroup(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l.signUpSubtitle,
                    style: TextStyle(fontSize: 15, height: 1.4, color: c.muted),
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) {
                      final error = auth.errorMessage;
                      if (error == null) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: c.danger),
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: Text(
                          error,
                          style: TextStyle(fontSize: 14, color: c.danger),
                        ),
                      );
                    },
                  ),
                  _label(l.ssoOnboardingFirstNameLabel, c),
                  TextFormField(
                    controller: _firstNameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.givenName],
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.ssoOnboardingFirstNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _label(l.ssoOnboardingLastNameLabel, c),
                  TextFormField(
                    controller: _lastNameController,
                    textCapitalization: TextCapitalization.words,
                    autofillHints: const [AutofillHints.familyName],
                    textInputAction: TextInputAction.next,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? l.ssoOnboardingLastNameRequired
                        : null,
                  ),
                  const SizedBox(height: 16),
                  _label(l.loginEmailLabel, c),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    autocorrect: false,
                    autofillHints: const [AutofillHints.email],
                    textInputAction: TextInputAction.next,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return l.loginEmailRequired;
                      if (!value.contains('@')) return l.loginEmailInvalid;
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _label(l.loginPasswordLabel, c),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    autofillHints: const [AutofillHints.newPassword],
                    textInputAction: TextInputAction.next,
                    decoration: InputDecoration(
                      helperText: l.signUpPasswordRules,
                      helperMaxLines: 3,
                      suffixIcon: IconButton(
                        tooltip: l.loginShowPassword,
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    validator: (v) => _validatePassword(v, l),
                  ),
                  const SizedBox(height: 16),
                  _label(l.signUpConfirmPasswordLabel, c),
                  TextFormField(
                    controller: _confirmController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (v) => v == _passwordController.text
                        ? null
                        : l.signUpPasswordsDoNotMatch,
                    onFieldSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 24),
                  Consumer<AuthProvider>(
                    builder: (context, auth, _) => ElevatedButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l.signUpSubmit),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text.rich(
                    TextSpan(
                      style: TextStyle(fontSize: 13, color: c.muted),
                      children: [
                        TextSpan(text: l.signUpAgreementPrefix),
                        TextSpan(
                          text: l.legalTerms,
                          style: TextStyle(color: c.moneyIn),
                          recognizer: _termsRecognizer,
                        ),
                        TextSpan(text: l.signUpAgreementAnd),
                        TextSpan(
                          text: l.legalPrivacy,
                          style: TextStyle(color: c.moneyIn),
                          recognizer: _privacyRecognizer,
                        ),
                        const TextSpan(text: '.'),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
