import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../models/merchant.dart';
import '../providers/auth_provider.dart';
import '../providers/merchants_provider.dart';
import '../widgets/ledger/ledger.dart';

/// Saved people and businesses the family pays or gets paid by.
class PeopleScreen extends StatefulWidget {
  const PeopleScreen({super.key});

  @override
  State<PeopleScreen> createState() => _PeopleScreenState();
}

class _PeopleScreenState extends State<PeopleScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load({bool force = false}) async {
    final provider = context.read<MerchantsProvider>();
    final token = await context.read<AuthProvider>().getValidAccessToken();
    if (token == null) return;
    await provider.fetchMerchants(accessToken: token, forceRefresh: force);
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final provider = context.watch<MerchantsProvider>();
    final people = provider.merchants.where((m) => m.isEditable).toList();

    return Scaffold(
      backgroundColor: c.paper,
      body: SafeArea(
        child: Column(
          children: [
            if (Navigator.of(context).canPop()) const LedgerBackHeader(),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _load(force: true),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
                  children: [
                    Text(l.peopleTitle, style: LedgerText.title(color: c.ink)),
                    const SizedBox(height: 8),
                    Text(l.peopleIntro,
                        style: LedgerText.body(size: 14, color: c.muted)),
                    const SizedBox(height: 20),
                    InkButton(
                      key: const Key('peopleAdd'),
                      label: l.peopleAdd,
                      height: 48,
                      onPressed: () => showPersonSheet(context),
                    ),
                    const SizedBox(height: 24),
                    if (provider.isLoading && people.isEmpty)
                      const Padding(
                        padding: EdgeInsets.only(top: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (provider.error != null && people.isEmpty)
                      Text(l.peopleLoadFailed,
                          style: LedgerText.body(color: c.moneyOut))
                    else if (people.isEmpty)
                      Text(l.peopleEmpty,
                          style: LedgerText.body(color: c.muted))
                    else
                      for (final person in people)
                        _PersonRow(
                          person: person,
                          onTap: () => showPersonSheet(context, person: person),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PersonRow extends StatelessWidget {
  const _PersonRow({required this.person, required this.onTap, this.trailing});

  final Merchant person;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final details = person.details;
    return InkWell(
      key: ValueKey('person-${person.id}'),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: c.hairline)),
        ),
        child: Row(
          children: [
            LabelDot(color: parseHexColor(person.color, c.muted), size: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(person.name, style: LedgerText.body(color: c.ink)),
                  if (details.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(details,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: LedgerText.body(size: 13, color: c.muted)),
                  ],
                ],
              ),
            ),
            trailing ??
                Icon(Icons.edit_outlined,
                    size: 18,
                    color: c.muted,
                    semanticLabel: AppLocalizations.of(context).peopleEdit),
          ],
        ),
      ),
    );
  }
}

/// Opens the add / edit sheet. Returns the saved person, or null when
/// cancelled or deleted.
Future<Merchant?> showPersonSheet(
  BuildContext context, {
  Merchant? person,
  String? initialName,
}) {
  return showModalBottomSheet<Merchant>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LedgerColors.of(context).paper,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _PersonSheet(person: person, initialName: initialName),
  );
}

class _PersonSheet extends StatefulWidget {
  const _PersonSheet({this.person, this.initialName});

  final Merchant? person;
  final String? initialName;

  @override
  State<_PersonSheet> createState() => _PersonSheetState();
}

class _PersonSheetState extends State<_PersonSheet> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final _name =
      TextEditingController(text: widget.person?.name ?? widget.initialName);
  late final _profession =
      TextEditingController(text: widget.person?.profession);
  late final _phone = TextEditingController(text: widget.person?.phone);
  late final _email = TextEditingController(text: widget.person?.email);
  late final _notes = TextEditingController(text: widget.person?.notes);
  bool _busy = false;
  String? _error;

  bool get _editing => widget.person != null;

  @override
  void dispose() {
    for (final controller in [_name, _profession, _phone, _email, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.isEmpty) {
      setState(() => _error = l.peopleNameRequired);
      return;
    }
    if (email.isNotEmpty && !_emailPattern.hasMatch(email)) {
      setState(() => _error = l.peopleEmailInvalid);
      return;
    }
    final provider = context.read<MerchantsProvider>();
    final token = await context.read<AuthProvider>().getValidAccessToken();
    if (token == null || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });

    // Blank strings clear a saved value on edit.
    final fields = <String, String?>{
      'name': name,
      'profession': _profession.text.trim(),
      'phone': _phone.text.trim(),
      'email': email,
      'notes': _notes.text.trim(),
    };
    final saved = _editing
        ? await provider.updateMerchant(
            accessToken: token,
            merchantId: widget.person!.id,
            fields: fields,
          )
        : await provider.createMerchant(accessToken: token, fields: fields);
    if (!mounted) return;
    if (saved != null) {
      Navigator.of(context).pop(saved);
    } else {
      setState(() {
        _busy = false;
        _error = provider.error ?? l.peopleSaveFailed;
      });
    }
  }

  Future<void> _delete() async {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final person = widget.person!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: const RoundedRectangleBorder(),
        title: Text(l.commonDeleteNamed(person.name)),
        content: Text(l.peopleDeleteBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l.commonKeep),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l.commonDelete, style: TextStyle(color: c.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final provider = context.read<MerchantsProvider>();
    final token = await context.read<AuthProvider>().getValidAccessToken();
    if (token == null || !mounted) return;
    setState(() => _busy = true);
    final ok = await provider.deleteMerchant(
        accessToken: token, merchantId: person.id);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _busy = false;
        _error = provider.error ?? l.peopleDeleteFailed;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final labelStyle =
        LedgerText.body(size: 14, weight: FontWeight.w500, color: c.ink);

    Widget field(
      String label,
      TextEditingController controller, {
      Key? key,
      String? hint,
      TextInputType? keyboard,
      TextCapitalization caps = TextCapitalization.none,
      int maxLines = 1,
      bool autofocus = false,
    }) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label, style: labelStyle),
            const SizedBox(height: 6),
            TextField(
              key: key,
              controller: controller,
              autofocus: autofocus,
              keyboardType: keyboard,
              textCapitalization: caps,
              minLines: 1,
              maxLines: maxLines,
              textInputAction:
                  maxLines > 1 ? TextInputAction.newline : TextInputAction.next,
              style: LedgerText.body(color: c.ink),
              decoration: ledgerInputDecoration(context, hint: hint),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            LedgerSectionHeader(
                title: _editing ? l.peopleEdit : l.peopleNewPerson),
            const SizedBox(height: 16),
            field(l.peopleName, _name,
                key: const Key('personName'),
                hint: l.peopleNameHint,
                caps: TextCapitalization.words,
                autofocus: !_editing),
            field(l.peopleProfession, _profession,
                hint: l.peopleProfessionHint,
                caps: TextCapitalization.sentences),
            field(l.peoplePhone, _phone,
                hint: l.formOptional, keyboard: TextInputType.phone),
            field(l.peopleEmail, _email,
                hint: l.formOptional, keyboard: TextInputType.emailAddress),
            field(l.detailNote, _notes,
                hint: l.formOptional,
                caps: TextCapitalization.sentences,
                maxLines: 3),
            if (_error != null) ...[
              Text(_error!,
                  style: LedgerText.body(size: 14, color: c.moneyOut)),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 4),
            InkButton(
              key: const Key('personSave'),
              label: l.commonSave,
              busy: _busy,
              onPressed: _save,
            ),
            if (_editing) ...[
              const SizedBox(height: 8),
              TextButton(
                onPressed: _busy ? null : _delete,
                style: TextButton.styleFrom(minimumSize: const Size(44, 48)),
                child: Text(l.peopleDelete,
                    style: LedgerText.body(size: 15, color: c.danger)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// What the person picker returned: [person] is null for "No one".
class PersonPick {
  const PersonPick(this.person);
  final Merchant? person;
}

/// Bottom sheet to choose who was paid or who paid. Returns null when
/// dismissed without a choice.
Future<PersonPick?> showPersonPicker(
  BuildContext context, {
  String? selectedId,
}) {
  return showModalBottomSheet<PersonPick>(
    context: context,
    isScrollControlled: true,
    backgroundColor: LedgerColors.of(context).paper,
    shape: const RoundedRectangleBorder(),
    builder: (_) => _PersonPicker(selectedId: selectedId),
  );
}

class _PersonPicker extends StatefulWidget {
  const _PersonPicker({this.selectedId});

  final String? selectedId;

  @override
  State<_PersonPicker> createState() => _PersonPickerState();
}

class _PersonPickerState extends State<_PersonPicker> {
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final provider = context.read<MerchantsProvider>();
      final token = await context.read<AuthProvider>().getValidAccessToken();
      if (token != null) provider.fetchMerchants(accessToken: token);
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _addNew() async {
    final typed = _search.text.trim();
    final person = await showPersonSheet(
      context,
      initialName: typed.isEmpty ? null : typed,
    );
    if (person != null && mounted) {
      Navigator.of(context).pop(PersonPick(person));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = LedgerColors.of(context);
    final l = AppLocalizations.of(context);
    final provider = context.watch<MerchantsProvider>();
    final query = _search.text.trim().toLowerCase();
    final people = provider.merchants
        .where((m) =>
            query.isEmpty ||
            m.name.toLowerCase().contains(query) ||
            m.details.toLowerCase().contains(query))
        .toList();
    final selected = Icon(Icons.check, size: 20, color: c.moneyIn);

    return SafeArea(
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
                child: TextField(
                  key: const Key('personSearch'),
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: LedgerText.body(color: c.ink),
                  decoration:
                      ledgerInputDecoration(context, hint: l.peopleSearchHint),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    ListTile(
                      key: const Key('personAddNew'),
                      contentPadding: EdgeInsets.zero,
                      leading: Icon(Icons.person_add_alt, color: c.moneyIn),
                      title: Text(
                        query.isEmpty
                            ? l.peopleAdd
                            : l.peopleAddNamed(_search.text.trim()),
                        style: LedgerText.body(color: c.moneyIn),
                      ),
                      onTap: _addNew,
                    ),
                    if (widget.selectedId != null)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading:
                            Icon(Icons.person_off_outlined, color: c.muted),
                        title: Text(l.peopleNoOne,
                            style: LedgerText.body(color: c.ink)),
                        onTap: () =>
                            Navigator.of(context).pop(const PersonPick(null)),
                      ),
                    if (provider.isLoading && people.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: CircularProgressIndicator()),
                      ),
                    for (final person in people)
                      _PersonRow(
                        person: person,
                        trailing: person.id == widget.selectedId
                            ? selected
                            : const SizedBox.shrink(),
                        onTap: () =>
                            Navigator.of(context).pop(PersonPick(person)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
