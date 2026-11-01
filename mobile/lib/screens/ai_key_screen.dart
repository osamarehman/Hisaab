import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/ai_settings_service.dart';
import '../widgets/ledger/ledger.dart';

/// The household's own AI key: pick a free OpenAI-compatible provider, paste
/// a key, test it and save it. Pops with `true` after a successful save.
class AiKeyScreen extends StatefulWidget {
  const AiKeyScreen({super.key, this.service, this.tokenLoader});

  /// Test seams; production uses the real service and the signed-in token.
  final AiSettingsService? service;
  final Future<String?> Function()? tokenLoader;

  @override
  State<AiKeyScreen> createState() => _AiKeyScreenState();
}

class _AiKeyScreenState extends State<AiKeyScreen> {
  /// Used until the server's list arrives, and if it sends none.
  static const _fallbackPresets = [
    AiPreset(
      id: 'gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai/',
      model: 'gemini-2.5-flash',
    ),
    AiPreset(
      id: 'openrouter',
      baseUrl: 'https://openrouter.ai/api/v1',
      model: 'meta-llama/llama-3.3-70b-instruct:free',
    ),
    AiPreset(
      id: 'groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      model: 'llama-3.3-70b-versatile',
    ),
  ];

  static const _providerNames = {
    'gemini': 'Google Gemini',
    'openrouter': 'OpenRouter',
    'groq': 'Groq',
  };

  static const _keyPages = {
    'gemini': 'aistudio.google.com/apikey',
    'openrouter': 'openrouter.ai/keys',
    'groq': 'console.groq.com/keys',
  };

  late final AiSettingsService _service = widget.service ?? AiSettingsService();
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _modelController = TextEditingController();

  AiSettings? _settings;
  List<AiPreset> _presets = _fallbackPresets;
  String _preset = 'gemini';
  bool _loading = true;
  bool _saving = false;
  bool _testing = false;
  String? _loadError;
  String? _testMessage;
  bool _testOk = false;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _applyPreset('gemini');
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _modelController.dispose();
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
        _loadError = l.aiKeyLoadFailed;
      });
      return;
    }
    final result = await _service.fetch(accessToken: token);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (result.ok) {
        _loadError = null;
        _show(result.settings!);
      } else {
        _loadError = l.aiKeyLoadFailed;
      }
    });
  }

  void _show(AiSettings settings) {
    _settings = settings;
    if (settings.presets.isNotEmpty) _presets = settings.presets;
    _keyController.clear();
    if (settings.keyPresent) {
      _preset = settings.preset ?? 'custom';
      _baseUrlController.text = settings.baseUrl ?? '';
      _modelController.text = settings.model ?? '';
    } else {
      _applyPreset(_preset);
    }
  }

  void _applyPreset(String id) {
    _preset = id;
    _testMessage = null;
    final preset = _presets.where((p) => p.id == id).firstOrNull;
    if (preset != null) {
      _baseUrlController.text = preset.baseUrl;
      _modelController.text = preset.model;
    } else {
      _baseUrlController.clear();
      _modelController.clear();
    }
  }

  bool get _hasKey => _settings?.keyPresent ?? false;

  /// Saving needs a key unless one is already stored.
  bool _validate(AppLocalizations l) {
    if (_keyController.text.trim().isEmpty && !_hasKey) {
      setState(() => _saveError = l.aiKeyKeyRequired);
      return false;
    }
    if (_baseUrlController.text.trim().isEmpty ||
        _modelController.text.trim().isEmpty) {
      setState(() => _saveError = l.aiKeyFieldsRequired);
      return false;
    }
    setState(() => _saveError = null);
    return true;
  }

  String _errorText(AppLocalizations l, String? error, String fallback) {
    if (error == AiSettingsResult.offline) return l.aiKeyOffline;
    return (error == null || error.isEmpty) ? fallback : error;
  }

  Future<void> _test() async {
    final l = AppLocalizations.of(context);
    if (!_validate(l)) return;
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() {
      _testing = true;
      _testMessage = null;
    });
    final result = await _service.test(
      accessToken: token,
      preset: _preset,
      apiKey: _keyController.text,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
    );
    if (!mounted) return;
    setState(() {
      _testing = false;
      _testOk = result.ok;
      _testMessage = result.ok
          ? l.aiKeyTestOk
          : l.aiKeyTestFailed(_errorText(l, result.error, l.aiKeyTestUnknown));
    });
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_validate(l)) return;
    final token = await _token();
    if (token == null || !mounted) return;
    setState(() => _saving = true);
    final result = await _service.save(
      accessToken: token,
      preset: _preset,
      apiKey: _keyController.text,
      baseUrl: _baseUrlController.text,
      model: _modelController.text,
    );
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (result.ok) {
        _show(result.settings!);
      } else {
        _saveError = _errorText(l, result.error, l.aiKeySaveFailed);
      }
    });
    if (!result.ok) return;
    _toast(l.aiKeySavedToast);
    if (Navigator.of(context).canPop()) Navigator.of(context).pop(true);
  }

  Future<void> _remove() async {
    final l = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l.aiKeyRemoveTitle),
        content: Text(l.aiKeyRemoveBody),
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
            child: Text(l.aiKeyRemove),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = await _token();
    if (token == null || !mounted) return;
    final result = await _service.remove(accessToken: token);
    if (!mounted) return;
    if (result.ok) {
      setState(() {
        _preset = 'gemini';
        _show(result.settings!);
        _testMessage = null;
      });
      _toast(l.aiKeyRemovedToast);
    } else {
      _toast(_errorText(l, result.error, l.aiKeyRemoveFailed));
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
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                children: [
                  Text(l.aiKeyTitle, style: LedgerText.title(color: c.ink)),
                  const SizedBox(height: 12),
                  Text(l.aiKeyIntro, style: LedgerText.body(color: c.muted)),
                  const SizedBox(height: 24),
                  ..._content(c, l),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _content(LedgerColors c, AppLocalizations l) {
    if (_loading) {
      return const [
        Padding(
          padding: EdgeInsets.only(top: 32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ];
    }
    if (_loadError != null) {
      return [Text(_loadError!, style: LedgerText.body(color: c.danger))];
    }
    final settings = _settings!;
    return [
      Text(
        settings.keyPresent
            ? l.aiKeyStatusSaved(_providerName(l, _preset),
                settings.keyLast4 ?? '')
            : l.aiKeyStatusNone,
        key: const Key('aiKeyStatus'),
        style: LedgerText.body(weight: FontWeight.w600, color: c.ink),
      ),
      const SizedBox(height: 16),
      if (!settings.canEdit)
        Text(l.aiKeyAdminOnly, style: LedgerText.body(color: c.muted))
      else
        _form(c, l, settings),
    ];
  }

  String _providerName(AppLocalizations l, String id) =>
      _providerNames[id] ?? l.aiKeyCustom;

  Widget _form(LedgerColors c, AppLocalizations l, AiSettings settings) {
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);
    final keyPage = _keyPages[_preset];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LedgerPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(l.aiKeyProviderLabel, style: labelStyle),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in [..._presets.map((p) => p.id), 'custom'])
                    LabelChip(
                      key: Key('aiPreset-$id'),
                      name: _providerName(l, id),
                      showDot: false,
                      selected: _preset == id,
                      onTap: () => setState(() => _applyPreset(id)),
                    ),
                ],
              ),
              if (keyPage != null) ...[
                const SizedBox(height: 8),
                Text(l.aiKeyWhereToGet(keyPage),
                    style: LedgerText.body(size: 13, color: c.muted)),
              ],
              const SizedBox(height: 16),
              Text(l.aiKeyKeyLabel, style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                key: const Key('aiKeyField'),
                controller: _keyController,
                textDirection: TextDirection.ltr,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                style: LedgerText.body(color: c.ink),
                decoration: ledgerInputDecoration(
                  context,
                  hint: settings.keyPresent
                      ? l.aiKeyKeyKeepHint
                      : l.aiKeyKeyHint,
                ),
              ),
              const SizedBox(height: 12),
              Text(l.aiKeyModelLabel, style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                key: const Key('aiModelField'),
                controller: _modelController,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                style: LedgerText.body(color: c.ink),
                decoration: ledgerInputDecoration(context),
              ),
              const SizedBox(height: 12),
              Text(l.aiKeyBaseUrlLabel, style: labelStyle),
              const SizedBox(height: 6),
              TextField(
                key: const Key('aiBaseUrlField'),
                controller: _baseUrlController,
                textDirection: TextDirection.ltr,
                autocorrect: false,
                keyboardType: TextInputType.url,
                style: LedgerText.body(color: c.ink),
                decoration: ledgerInputDecoration(context),
                onChanged: (_) {
                  if (_preset != 'custom') setState(() => _preset = 'custom');
                },
              ),
              if (_saveError != null) ...[
                const SizedBox(height: 12),
                Text(_saveError!,
                    style: LedgerText.body(size: 14, color: c.danger)),
              ],
              if (_testMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _testMessage!,
                  key: const Key('aiKeyTestResult'),
                  style: LedgerText.body(
                      size: 14, color: _testOk ? c.moneyIn : c.danger),
                ),
              ],
              const SizedBox(height: 16),
              _testing
                  ? const Center(child: CircularProgressIndicator())
                  : OutlineInkButton(
                      key: const Key('aiKeyTest'),
                      label: l.aiKeyTest,
                      height: 48,
                      onPressed: _saving ? null : _test,
                    ),
              const SizedBox(height: 12),
              InkButton(
                key: const Key('aiKeySave'),
                label: l.aiKeySave,
                height: 48,
                busy: _saving,
                onPressed: _testing ? null : _save,
              ),
            ],
          ),
        ),
        if (settings.keyPresent) ...[
          const SizedBox(height: 16),
          TextButton(
            key: const Key('aiKeyRemove'),
            onPressed: _saving || _testing ? null : _remove,
            style: TextButton.styleFrom(foregroundColor: c.danger),
            child: Text(l.aiKeyRemove),
          ),
        ],
        const SizedBox(height: 16),
        Text(l.aiKeyPrivacyNote, style: LedgerText.body(size: 13, color: c.muted)),
      ],
    );
  }
}
