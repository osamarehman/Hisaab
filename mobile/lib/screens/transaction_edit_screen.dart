import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/offline_transaction.dart';
import '../models/transaction.dart';
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/connectivity_service.dart';
import '../services/transactions_service.dart';
import '../widgets/ledger/ledger.dart';

/// Transaction detail: amount, label, receipt, name and note. Pops `true`
/// when something changed.
class TransactionEditScreen extends StatefulWidget {
  const TransactionEditScreen({super.key, required this.transaction});

  final Transaction transaction;

  @override
  State<TransactionEditScreen> createState() => _TransactionEditScreenState();
}

class _TransactionEditScreenState extends State<TransactionEditScreen> {
  static const _maxNameLength = 255;
  static const _maxNotesLength = 2000;

  final _formKey = GlobalKey<FormState>();
  final _service = TransactionsService();
  late final TextEditingController _nameController;
  late final TextEditingController _notesController;
  late Transaction _tx;
  String? _categoryId;
  bool _saving = false;
  bool _receiptBusy = false;
  bool _changed = false;
  String? _accessToken;

  @override
  void initState() {
    super.initState();
    _tx = widget.transaction;
    _nameController = TextEditingController(text: _tx.name);
    _notesController = TextEditingController(text: _tx.notes ?? '');
    _categoryId = _tx.categoryId;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    final categories = context.read<CategoriesProvider>();
    final token = await auth.getValidAccessToken();
    if (token == null || !mounted) return;
    setState(() => _accessToken = token);
    categories.fetchCategories(accessToken: token);
    // Offline-cached rows lack attachments; refresh from the server.
    if (_tx.id != null) {
      final result = await _service.getTransaction(
          accessToken: token, transactionId: _tx.id!);
      if (mounted && result['success'] == true) {
        setState(() => _tx = result['transaction'] as Transaction);
      }
    }
  }

  bool get _online => context.read<ConnectivityService?>()?.isOnline ?? true;

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<String?> _token() async {
    final token = await context.read<AuthProvider>().getValidAccessToken();
    if (token == null && mounted) {
      _toast(AppLocalizations.of(context).transactionEditSessionExpired);
    }
    return token;
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate() || _tx.id == null) return;
    setState(() => _saving = true);
    final provider = context.read<TransactionsProvider>();
    final token = await _token();
    if (token == null) {
      if (mounted) setState(() => _saving = false);
      return;
    }

    final tx = _tx;
    final offline = tx is OfflineTransaction
        ? tx
        : OfflineTransaction.fromTransaction(tx, localId: tx.id!);
    final success = await provider.updateTransaction(
      accessToken: token,
      transaction: offline,
      name: _nameController.text.trim(),
      // Empty notes intentionally clear the server-side note.
      notes: _notesController.text.trim(),
      categoryId: _categoryId,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (success) {
      Navigator.pop(context, true);
    } else {
      _toast(provider.error ?? l.transactionEditUpdateFailed);
    }
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    if (_tx.id == null) return;
    final provider = context.read<TransactionsProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.transactionsListDeleteTitle),
        content: Text(l.transactionsListDeleteSingleContent(_tx.name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.commonCancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: LedgerColors.of(context).danger,
            ),
            child: Text(l.commonDelete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final token = await _token();
    if (token == null) return;
    final ok = await provider.deleteTransaction(
        accessToken: token, transactionId: _tx.id!);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      _toast(l.transactionsListSingleDeleteFailed);
    }
  }

  /// Uploads a new receipt; with [replace], removes the old one afterwards.
  Future<void> _attach({TransactionAttachment? replace}) async {
    final l = AppLocalizations.of(context);
    if (_tx.id == null) return;
    if (!_online) {
      _toast(l.receiptNeedsInternet);
      return;
    }
    final File? file = await showReceiptSourceSheet(context);
    if (file == null || !mounted) return;
    final token = await _token();
    if (token == null) return;
    setState(() => _receiptBusy = true);
    final result = await _service.uploadAttachments(
      accessToken: token,
      transactionId: _tx.id!,
      files: [file],
    );
    if (result['success'] == true && replace != null) {
      await _service.deleteAttachment(
        accessToken: token,
        transactionId: _tx.id!,
        attachmentId: replace.id,
      );
    }
    final refreshed = await _service.getTransaction(
        accessToken: token, transactionId: _tx.id!);
    if (!mounted) return;
    setState(() {
      _receiptBusy = false;
      if (refreshed['success'] == true) {
        _tx = refreshed['transaction'] as Transaction;
      }
      _changed = _changed || result['success'] == true;
    });
    if (result['success'] != true) {
      _toast(result['error']?.toString() ?? l.receiptUploadFailed);
    }
  }

  Future<void> _remove(TransactionAttachment attachment) async {
    final l = AppLocalizations.of(context);
    if (_tx.id == null) return;
    final token = await _token();
    if (token == null) return;
    setState(() => _receiptBusy = true);
    final result = await _service.deleteAttachment(
      accessToken: token,
      transactionId: _tx.id!,
      attachmentId: attachment.id,
    );
    if (!mounted) return;
    setState(() {
      _receiptBusy = false;
      if (result['success'] == true) {
        _changed = true;
        _tx = _copyWithAttachments(
          _tx,
          _tx.attachments.where((a) => a.id != attachment.id).toList(),
        );
      }
    });
    if (result['success'] != true) _toast(l.receiptRemoveFailed);
  }

  static Transaction _copyWithAttachments(
    Transaction t,
    List<TransactionAttachment> attachments,
  ) {
    final json = t.toJson()
      ..['attachments'] = attachments.map((a) => a.toJson()).toList()
      ..['account'] = {'id': t.accountId, 'name': t.accountName}
      ..['amount_decimal'] = t.amountDecimal
      ..['kind'] = t.kind;
    if (t.categoryId != null) {
      json['category'] = {
        'id': t.categoryId,
        'name': t.categoryName,
        'color': t.categoryColor,
      };
    }
    return Transaction.fromJson(json);
  }

  String? _validateName(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l.transactionEditNameRequired;
    }
    if (value.trim().length > _maxNameLength) {
      return l.transactionEditNameMaxLength(_maxNameLength);
    }
    if (_containsControlCharacter(value)) {
      return l.transactionEditNameInvalidChars;
    }
    return null;
  }

  String? _validateNotes(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) return null;
    if (value.trim().length > _maxNotesLength) {
      return l.transactionEditNotesMaxLength(_maxNotesLength);
    }
    if (_containsControlCharacter(value, allowWhitespace: true)) {
      return l.transactionEditNotesInvalidChars;
    }
    return null;
  }

  static bool _containsControlCharacter(
    String value, {
    bool allowWhitespace = false,
  }) {
    for (final codeUnit in value.codeUnits) {
      if (codeUnit == 127) return true;
      if (codeUnit < 32) {
        final allowedWhitespace = allowWhitespace &&
            (codeUnit == 9 || codeUnit == 10 || codeUnit == 13);
        if (!allowedWhitespace) return true;
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final categories = context.watch<CategoriesProvider>().categories;
    final accounts = context.watch<AccountsProvider>().accounts;
    final accountName = _tx.accountName ??
        accounts.where((a) => a.id == _tx.accountId).firstOrNull?.name;
    final date = DateTime.tryParse(_tx.date);
    final subtitle = [
      if (date != null) DateFormat('EEE d MMM yyyy', 'en_US').format(date),
      if (accountName != null && accountName.isNotEmpty) accountName,
    ].join(' · ');
    final canEdit = _tx.id != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 0,
          title: TextButton.icon(
            onPressed: () => Navigator.of(context).pop(_changed),
            icon: const Icon(Icons.chevron_left),
            label: Text(l.navActivity, style: const TextStyle(fontSize: 16)),
          ),
          actions: [
            if (canEdit)
              IconButton(
                tooltip: l.detailDelete,
                onPressed: _saving ? null : _delete,
                icon: Icon(Icons.delete_outline, color: c.danger),
              ),
          ],
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              if (subtitle.isNotEmpty)
                Text(subtitle, style: TextStyle(fontSize: 14, color: c.muted)),
              const SizedBox(height: 6),
              HeadlineAmount(
                _tx.absAmount,
                currency: _tx.currency,
                size: 46,
              ),
              const SizedBox(height: 6),
              Text(
                _tx.isIncome ? l.detailMoneyIn : l.detailMoneyOut,
                style: TextStyle(
                  fontSize: 13,
                  color: _tx.isIncome ? c.moneyIn : c.moneyOut,
                ),
              ),
              if (!canEdit) ...[
                const SizedBox(height: 16),
                Text(l.transactionEditSyncedOnly,
                    style: TextStyle(fontSize: 14, color: c.muted)),
              ],
              const SizedBox(height: 24),
              Text(l.formLabel,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cat in categories)
                    LabelChip(
                      name: cat.name,
                      color: parseHexColor(cat.color, c.ink),
                      selected: _categoryId == cat.id,
                      onTap: canEdit
                          ? () => setState(() => _categoryId = cat.id)
                          : null,
                    ),
                  if (categories.isEmpty && _tx.categoryName != null)
                    LabelChip(
                      name: _tx.categoryName!,
                      color: parseHexColor(_tx.categoryColor, c.ink),
                      selected: true,
                    ),
                ],
              ),
              const SizedBox(height: 24),
              _receiptSection(l, c, canEdit),
              const SizedBox(height: 24),
              Container(
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: c.ink)),
                ),
                child: Column(
                  children: [
                    _fieldRow(
                      c,
                      l.transactionEditNameLabel,
                      TextFormField(
                        controller: _nameController,
                        enabled: canEdit,
                        decoration: _bare,
                        validator: _validateName,
                        textInputAction: TextInputAction.next,
                      ),
                    ),
                    _fieldRow(
                      c,
                      l.detailNote,
                      TextFormField(
                        controller: _notesController,
                        enabled: canEdit,
                        minLines: 1,
                        maxLines: 4,
                        decoration: _bare.copyWith(hintText: l.detailNoteHint),
                        validator: _validateNotes,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: canEdit
            ? LedgerBottomBar(
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(l.commonSave),
                ),
              )
            : null,
      ),
    );
  }

  static const _bare = InputDecoration(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    disabledBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 14),
  );

  Widget _fieldRow(LedgerColors c, String label, Widget field) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Padding(
              padding: const EdgeInsets.only(top: 16),
              child:
                  Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
            ),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _receiptSection(AppLocalizations l, LedgerColors c, bool canEdit) {
    final attachment = _tx.attachments.firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(l.detailReceipt,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ),
            if (canEdit && !_receiptBusy)
              TextButton(
                onPressed: () => _attach(replace: attachment),
                child: Text(attachment == null
                    ? l.detailAttachReceipt
                    : l.detailReplaceReceipt),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (_receiptBusy)
          const SizedBox(
            height: 88,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (attachment == null)
          Text(l.detailNoReceipt,
              style: TextStyle(fontSize: 14, color: c.muted))
        else
          Container(
            decoration: BoxDecoration(border: Border.all(color: c.ink)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (attachment.isImage && _accessToken != null)
                  ReceiptImage(url: attachment.url, accessToken: _accessToken!)
                else
                  SizedBox(
                    height: 88,
                    child: Icon(Icons.picture_as_pdf_outlined,
                        size: 36, color: c.muted),
                  ),
                Container(
                  color: c.sheet,
                  padding: const EdgeInsets.only(left: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          _describe(attachment),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: LedgerText.figures(size: 13, color: c.ink),
                        ),
                      ),
                      if (canEdit)
                        IconButton(
                          tooltip: l.receiptRemove,
                          onPressed: () => _remove(attachment),
                          icon: Icon(Icons.close, color: c.ink),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (_tx.attachments.length > 1)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              l.detailMoreReceipts(_tx.attachments.length - 1),
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          ),
      ],
    );
  }

  static String _describe(TransactionAttachment a) {
    final size = a.byteSize;
    if (size == null) return a.filename;
    final kb = (size / 1024).round();
    return kb >= 1024
        ? '${a.filename} · ${(kb / 1024).toStringAsFixed(1)} MB'
        : '${a.filename} · $kb KB';
  }
}
