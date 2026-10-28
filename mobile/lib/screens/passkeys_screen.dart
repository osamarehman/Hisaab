import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/passkey_service.dart';
import '../widgets/ledger/ledger.dart';

/// Lists the signed-in user's passkeys and adds or removes them.
class PasskeysScreen extends StatefulWidget {
  const PasskeysScreen({super.key, this.service, this.tokenLoader});

  /// Test seams; production uses the real service and the signed-in token.
  final PasskeyService? service;
  final Future<String?> Function()? tokenLoader;

  @override
  State<PasskeysScreen> createState() => _PasskeysScreenState();
}

class _PasskeysScreenState extends State<PasskeysScreen> {
  late final PasskeyService _service = widget.service ?? PasskeyService();
  final _nameController = TextEditingController();
  final _confirmController = TextEditingController();

  List<Passkey> _passkeys = const [];
  PasskeyStepUp _stepUp = PasskeyStepUp.unavailable;
  bool _loading = true;
  bool _adding = false;
  String? _error;
  String? _confirmError;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<String?> _token() => widget.tokenLoader != null
      ? widget.tokenLoader!()
      : context.read<AuthProvider>().getValidAccessToken();

  Future<void> _load() async {
    final l = AppLocalizations.of(context);
    final token = await _token();
    if (!mounted) return;
    if (token == null) {
      setState(() {
        _loading = false;
        _error = l.passkeysLoadFailed;
      });
      return;
    }
    final result = await _service.list(accessToken: token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result['success'] == true) {
        _passkeys = result['passkeys'] as List<Passkey>;
        _stepUp = result['step_up'] as PasskeyStepUp;
        _error = null;
      } else {
        _error = l.passkeysLoadFailed;
      }
    });
  }

  Future<void> _add() async {
    final l = AppLocalizations.of(context);
    final confirmation = _confirmController.text.trim();
    if (confirmation.isEmpty) {
      setState(() => _confirmError = l.passkeysConfirmRequired);
      return;
    }
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() {
      _adding = true;
      _confirmError = null;
    });

    final result = await _service.add(
      accessToken: token,
      nickname: _nameController.text.trim(),
      code: _stepUp == PasskeyStepUp.code ? confirmation : null,
      password: _stepUp == PasskeyStepUp.password ? confirmation : null,
    );
    if (!mounted) return;
    setState(() => _adding = false);

    if (result['success'] == true) {
      _nameController.clear();
      _confirmController.clear();
      _toast(l.passkeysAddedToast);
      await _load();
      return;
    }
    if (result['cancelled'] == true) return;
    if (result['unsupported'] == true) {
      _toast(l.passkeysUnsupported);
      return;
    }
    final error = result['error'] as String?;
    if (result['status'] == 422 && error != null && error.isNotEmpty) {
      // A wrong password or code: show it on the field it belongs to.
      setState(() => _confirmError = error);
      return;
    }
    _toast(error == null || error.isEmpty ? l.passkeysAddFailed : error);
  }

  Future<void> _remove(Passkey passkey) async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.passkeysRemoveTitle),
        content: Text(l.passkeysRemoveBody(passkey.nickname)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(
              foregroundColor: LedgerColors.of(dialogContext).danger,
            ),
            child: Text(l.passkeysRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final token = await _token();
    if (token == null || !mounted) return;
    final result = await _service.remove(accessToken: token, id: passkey.id);
    if (!mounted) return;
    if (result['success'] == true) {
      _toast(l.passkeysRemovedToast);
      await _load();
    } else {
      _toast(l.passkeysRemoveFailed);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Text(l.settingsPasskeysTitle,
                        style: LedgerText.title(color: c.ink)),
                    const SizedBox(height: 12),
                    Text(l.passkeysIntro,
                        style: LedgerText.body(color: c.muted)),
                    const SizedBox(height: 24),
                    if (!_loading && _error == null) ...[
                      _addForm(c, l),
                      const SizedBox(height: 24),
                    ],
                    ..._list(c, l),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _addForm(LedgerColors c, AppLocalizations l) {
    if (!_service.isSupported) {
      return Text(l.passkeysUnsupported, style: LedgerText.body(color: c.muted));
    }
    if (_stepUp == PasskeyStepUp.unavailable) {
      return Text(l.passkeysNoStepUp, style: LedgerText.body(color: c.muted));
    }
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);
    final isCode = _stepUp == PasskeyStepUp.code;
    return LedgerPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.passkeysAddHeading,
              style: LedgerText.body(weight: FontWeight.w600, color: c.ink)),
          const SizedBox(height: 12),
          Text(l.passkeysNameLabel, style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            key: const Key('passkeyName'),
            controller: _nameController,
            textCapitalization: TextCapitalization.sentences,
            style: LedgerText.body(color: c.ink),
            decoration: ledgerInputDecoration(context, hint: l.passkeysNameHint),
          ),
          const SizedBox(height: 12),
          Text(isCode ? l.passkeysCodeLabel : l.passkeysPasswordLabel,
              style: labelStyle),
          const SizedBox(height: 6),
          TextField(
            key: const Key('passkeyConfirm'),
            controller: _confirmController,
            obscureText: !isCode,
            keyboardType: isCode ? TextInputType.number : null,
            autofillHints: [
              isCode ? AutofillHints.oneTimeCode : AutofillHints.password
            ],
            style: LedgerText.body(color: c.ink),
            decoration: ledgerInputDecoration(context).copyWith(
              errorText: _confirmError,
            ),
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: 12),
          InkButton(
            label: l.passkeysAddButton,
            height: 48,
            busy: _adding,
            onPressed: _add,
          ),
        ],
      ),
    );
  }

  List<Widget> _list(LedgerColors c, AppLocalizations l) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_error != null) {
      return [Text(_error!, style: LedgerText.body(color: c.moneyOut))];
    }
    return [
      LedgerCapsHeader(label: l.passkeysListHeading),
      for (final passkey in _passkeys) _row(c, l, passkey),
      if (_passkeys.isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Text(l.passkeysEmpty, style: LedgerText.body(color: c.muted)),
        ),
    ];
  }

  Widget _row(LedgerColors c, AppLocalizations l, Passkey passkey) {
    final format = DateFormat.yMMMd(Localizations.localeOf(context).toString());
    final details = [
      if (passkey.createdAt != null)
        l.passkeysAdded(format.format(passkey.createdAt!.toLocal())),
      if (passkey.lastUsedAt != null)
        l.passkeysLastUsed(format.format(passkey.lastUsedAt!.toLocal())),
    ].join(' · ');
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          Icon(Icons.fingerprint, size: 20, color: c.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(passkey.nickname, style: LedgerText.body(color: c.ink)),
                if (details.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(details,
                      style: LedgerText.figures(size: 12, color: c.muted)),
                ],
              ],
            ),
          ),
          TextButton(
            onPressed: () => _remove(passkey),
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l.passkeysRemove),
          ),
        ],
      ),
    );
  }
}
