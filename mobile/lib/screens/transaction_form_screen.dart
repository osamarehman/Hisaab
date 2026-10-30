import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/account.dart';
import '../models/category.dart' as models;
import '../providers/accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/categories_provider.dart';
import '../providers/transactions_provider.dart';
import '../services/connectivity_service.dart';
import '../services/log_service.dart';
import '../theme/sure_typography.dart';
import '../utils/amount_parser.dart';
import '../utils/money_format.dart';
import '../widgets/ledger/ledger.dart';
import '../widgets/no_accounts_prompt.dart';
import 'account_form_screen.dart';
import 'labels_screen.dart';

/// Add expense / income. Saves offline-first, then uploads the receipt once
/// the transaction reaches the server. Pops `true` when saved.
class TransactionFormScreen extends StatefulWidget {
  const TransactionFormScreen({super.key, this.account});

  /// Preselected "Paid from" account.
  final Account? account;

  @override
  State<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends State<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  final _log = LogService.instance;

  String _nature = 'expense';
  DateTime _date = DateTime.now();
  String? _accountId;
  models.Category? _category;
  File? _receipt;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _accountId = widget.account?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _amountController.dispose();
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load({bool forceLabels = false}) async {
    final auth = context.read<AuthProvider>();
    final categories = context.read<CategoriesProvider>();
    final accounts = context.read<AccountsProvider>();
    final token = await auth.getValidAccessToken();
    if (token == null) return;
    await Future.wait([
      categories.fetchCategories(accessToken: token, force: forceLabels),
      if (accounts.accounts.isEmpty) accounts.fetchAccounts(accessToken: token),
    ]);
  }

  /// Cash first, then the rest, so the common case needs no change.
  List<Account> _accounts(List<Account> all) {
    bool isCash(Account a) =>
        a.name.toLowerCase().contains('cash') ||
        a.subtype?.toLowerCase() == 'cash';
    return [...all.where(isCash), ...all.where((a) => !isCash(a))];
  }

  Future<void> _openLabels() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const LabelsScreen()),
    );
    if (mounted) await _load(forceLabels: true);
  }

  /// Dropdown value for "+ New account"; never an account id.
  static const _newAccountValue = '__new_account__';

  Future<void> _addAccount() async {
    final account = await openAccountForm(context);
    if (account != null && mounted) setState(() => _accountId = account.id);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && mounted) setState(() => _date = picked);
  }

  String? _validateAmount(String? value) {
    final l = AppLocalizations.of(context);
    if (value == null || value.trim().isEmpty) {
      return l.transactionFormAmountRequiredPrompt;
    }
    try {
      if (AmountParser.parse(value, locale: 'en_US').value <= 0) {
        return l.transactionFormAmountTooSmall;
      }
    } on FormatException {
      return l.transactionFormAmountInvalidNumber;
    }
    return null;
  }

  Future<void> _submit(Account? account) async {
    final l = AppLocalizations.of(context);
    if (!_formKey.currentState!.validate()) return;
    if (account == null) {
      _toast(l.formPickAccount);
      return;
    }
    setState(() => _submitting = true);

    final auth = context.read<AuthProvider>();
    final provider = context.read<TransactionsProvider>();
    final online = context.read<ConnectivityService?>()?.isOnline ?? true;

    try {
      final token = await auth.getValidAccessToken();
      if (token == null) {
        _toast(l.transactionFormSessionExpired);
        await auth.logout();
        return;
      }

      final name = _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : (_category?.name ??
              (_nature == 'income' ? l.formTypeIncome : l.formTypeExpense));
      final notes = _notesController.text.trim();

      final ok = await provider.createTransaction(
        accessToken: token,
        accountId: account.id,
        name: name,
        date: DateFormat('yyyy-MM-dd').format(_date),
        amount: AmountParser.canonicalize(
          _amountController.text,
          locale: 'en_US',
        ),
        currency: account.currency,
        nature: _nature,
        notes: notes.isEmpty ? null : notes,
        categoryId: _category?.id,
        categoryName: _category?.name,
        attachments: _receipt == null ? null : [_receipt!],
      );

      if (!mounted) return;
      if (ok) {
        _toast(!online && _receipt != null
            ? l.formSavedReceiptOffline
            : online
                ? l.formSaved
                : l.transactionFormCreateSuccessOffline);
        Navigator.pop(context, true);
      } else {
        _toast(l.transactionFormCreateFailed);
      }
    } catch (e) {
      _log.error('TransactionForm', 'Create failed with ${e.runtimeType}');
      if (mounted) _toast(l.transactionFormCreateFailed);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final c = LedgerColors.of(context);
    final categories = context.watch<CategoriesProvider>().categories;
    final accountsProvider = context.watch<AccountsProvider>();
    final accounts = _accounts(accountsProvider.accounts);
    final account = accounts.where((a) => a.id == _accountId).firstOrNull ??
        accounts.firstOrNull;
    final currency = account?.currency ?? accountsProvider.familyCurrency;
    final isIncome = _nature == 'income';

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leadingWidth: 96,
        leading: TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(l.commonCancel, style: const TextStyle(fontSize: 16)),
        ),
        centerTitle: true,
        title: _TypeToggle(
          value: _nature,
          expenseLabel: l.formTypeExpense,
          incomeLabel: l.formTypeIncome,
          onChanged: (v) => setState(() => _nature = v),
        ),
        actions: const [SizedBox(width: 96)],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 28, 20, 28),
          children: [
            if (accounts.isEmpty && !accountsProvider.isLoading) ...[
              NoAccountsPrompt(
                onCreated: (a) => setState(() => _accountId = a.id),
              ),
              const SizedBox(height: 26),
            ],
            Text(l.transactionFormAmountLabel,
                style: TextStyle(fontSize: 14, color: c.muted)),
            const SizedBox(height: 6),
            _amountField(c, currency),
            const SizedBox(height: 26),
            Row(
              children: [
                Expanded(
                  child: Text(l.formLabel,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                ),
                TextButton(onPressed: _openLabels, child: Text(l.formManage)),
              ],
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in categories)
                  LabelChip(
                    name: cat.name,
                    color: parseHexColor(cat.color, c.ink),
                    selected: _category?.id == cat.id,
                    onTap: () => setState(
                        () => _category = _category?.id == cat.id ? null : cat),
                  ),
                LabelChip(
                  name: l.formNewLabel,
                  subdued: true,
                  onTap: _openLabels,
                ),
              ],
            ),
            const SizedBox(height: 26),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.ink)),
              ),
              child: Column(
                children: [
                  _row(
                    c,
                    l.formWhatFor,
                    TextFormField(
                      controller: _nameController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: _bare.copyWith(hintText: l.formWhatForHint),
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  _row(
                    c,
                    isIncome ? l.formPaidInto : l.formPaidFrom,
                    accounts.isEmpty
                        ? Align(
                            alignment: AlignmentDirectional.centerStart,
                            child: TextButton(
                              onPressed: _addAccount,
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero,
                                  minimumSize: const Size(44, 48)),
                              child: Text('+ Add an account',
                                  style: TextStyle(
                                      fontSize: 16, color: c.moneyIn)),
                            ),
                          )
                        : DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: account?.id,
                              isExpanded: true,
                              style: TextStyle(fontSize: 16, color: c.ink),
                              items: [
                                for (final a in accounts)
                                  DropdownMenuItem(
                                    value: a.id,
                                    child: Text(a.name,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                DropdownMenuItem(
                                  value: _newAccountValue,
                                  child: Text('+ New account',
                                      style: TextStyle(color: c.moneyIn)),
                                ),
                              ],
                              onChanged: (id) {
                                if (id == _newAccountValue) {
                                  _addAccount();
                                } else {
                                  setState(() => _accountId = id);
                                }
                              },
                            ),
                          ),
                  ),
                  _row(
                    c,
                    l.transactionFormDateLabel,
                    InkWell(
                      onTap: _pickDate,
                      child: Container(
                        alignment: AlignmentDirectional.centerStart,
                        constraints: const BoxConstraints(minHeight: 52),
                        child: Text(
                          DateFormat('EEE d MMM yyyy', 'en_US').format(_date),
                          style: TextStyle(fontSize: 16, color: c.ink),
                        ),
                      ),
                    ),
                  ),
                  _row(
                    c,
                    l.detailNote,
                    TextFormField(
                      controller: _notesController,
                      minLines: 1,
                      maxLines: 3,
                      decoration: _bare.copyWith(hintText: l.formOptional),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            Text(l.formReceipt,
                style:
                    const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            if (_receipt == null)
              ReceiptSourceButtons(
                takePhotoLabel: l.receiptTakePhoto,
                galleryLabel: l.receiptFromGallery,
                onPick: (source) async {
                  final file = await pickReceipt(source);
                  if (file != null && mounted) setState(() => _receipt = file);
                },
              )
            else
              _receiptPreview(l, c),
          ],
        ),
      ),
      bottomNavigationBar: LedgerBottomBar(
        child: ElevatedButton(
          onPressed: _submitting ? null : () => _submit(account),
          child: _submitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isIncome ? l.formSaveIncome : l.formSaveExpense),
        ),
      ),
    );
  }

  static const _bare = InputDecoration(
    border: InputBorder.none,
    enabledBorder: InputBorder.none,
    focusedBorder: InputBorder.none,
    errorBorder: InputBorder.none,
    focusedErrorBorder: InputBorder.none,
    filled: false,
    isDense: true,
    contentPadding: EdgeInsets.symmetric(vertical: 16),
  );

  Widget _amountField(LedgerColors c, String? currency) {
    return Container(
      padding: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.ink, width: 2)),
      ),
      // "Rs 1,200" is entered left-to-right in every language.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              MoneyFormat.symbol(currency),
              style: LedgerText.display(size: 28, color: c.muted),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextFormField(
                controller: _amountController,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [GroupedAmountFormatter()],
                validator: _validateAmount,
                style: LedgerText.display(
                  size: 52,
                  color: c.ink,
                  letterSpacing: -1.5,
                  height: 1.1,
                ),
                decoration: _bare.copyWith(
                  hintText: '0',
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(LedgerColors c, String label, Widget field) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: c.hairline)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 104,
            child: Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
          ),
          Expanded(child: field),
        ],
      ),
    );
  }

  Widget _receiptPreview(AppLocalizations l, LedgerColors c) {
    final file = _receipt!;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: c.sheet,
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(2),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 96,
            decoration: BoxDecoration(border: Border.all(color: c.hairline)),
            child: Image.file(file, fit: BoxFit.cover),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              p.basename(file.path),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 15, color: c.ink),
            ),
          ),
          IconButton(
            tooltip: l.receiptRemove,
            onPressed: () => setState(() => _receipt = null),
            icon: Icon(Icons.close, color: c.ink),
          ),
        ],
      ),
    );
  }
}

/// Expense / Income segmented toggle with an ink-filled selected half.
class _TypeToggle extends StatelessWidget {
  const _TypeToggle({
    required this.value,
    required this.expenseLabel,
    required this.incomeLabel,
    required this.onChanged,
  });

  final String value;
  final String expenseLabel;
  final String incomeLabel;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    Widget half(String key, String label) {
      final on = value == key;
      return Semantics(
        selected: on,
        button: true,
        child: Material(
          color: on ? c.ink : Colors.transparent,
          child: InkWell(
            onTap: () => onChanged(key),
            child: Container(
              constraints: const BoxConstraints(minHeight: 44),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: SureFonts.sans,
                  fontFamilyFallback: SureFonts.fallback,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: on ? c.onInk : c.ink,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: c.ink),
        borderRadius: BorderRadius.circular(2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(1),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            half('expense', expenseLabel),
            half('income', incomeLabel)
          ],
        ),
      ),
    );
  }
}

/// Keeps the amount field as "2,450.5": digits, one dot, en-US grouping.
class GroupedAmountFormatter extends TextInputFormatter {
  static final _group = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var raw = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    final dot = raw.indexOf('.');
    if (dot != -1) {
      // Keep the first dot and at most two decimals.
      final decimals = raw.substring(dot + 1).replaceAll('.', '');
      raw =
          '${raw.substring(0, dot)}.${decimals.length > 2 ? decimals.substring(0, 2) : decimals}';
    }
    if (raw.isEmpty) return const TextEditingValue();
    final parts = raw.split('.');
    final whole = parts[0].isEmpty ? '0' : parts[0];
    final grouped = whole.length > 15 ? whole : _group.format(int.parse(whole));
    final text = parts.length > 1 ? '$grouped.${parts[1]}' : grouped;
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
