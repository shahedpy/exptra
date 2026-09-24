import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import 'account_controller.dart';

class AccountFormPage extends StatefulWidget {
  final Account? account;
  const AccountFormPage({super.key, this.account});
  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  static const types = [
    'Savings',
    'Current',
    'Cash',
    'Mobile Wallet',
    'FDR',
    'DPS',
    'Investment',
    'Other',
  ];
  final key = GlobalKey<FormState>();
  final institution = TextEditingController();
  final name = TextEditingController();
  final opening = TextEditingController(text: '0');
  final note = TextEditingController();
  String type = 'Savings';
  DateTime date = DateTime.now();
  bool include = true, archived = false, saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      institution.text = a.institutionName;
      name.text = a.name;
      opening.text = a.openingBalance.toStringAsFixed(2);
      note.text = a.note ?? '';
      type = a.type;
      date = a.openingBalanceDate;
      include = a.includeInNetWorth;
      archived = a.isArchived;
    }
  }

  @override
  void dispose() {
    institution.dispose();
    name.dispose();
    opening.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      final controller = Get.find<AccountController>();
      await controller.repository.saveAccount(
        id: widget.account?.id,
        institutionName: institution.text.trim(),
        name: name.text.trim(),
        type: type,
        currency: widget.account?.currency ?? 'BDT',
        openingBalance: CurrencyHelper.parseAmount(opening.text),
        openingBalanceDate: date,
        note: note.text.trim(),
        sortOrder: widget.account?.sortOrder ?? controller.accounts.length,
        includeInNetWorth: include,
        isArchived: archived,
      );
      await controller.reload();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.account == null ? 'Add Account' : 'Edit Account'),
    ),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextFormField(
            controller: institution,
            decoration: const InputDecoration(
              labelText: 'Institution (optional)',
              hintText: 'UCB, FSIB, City Bank',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: name,
            decoration: const InputDecoration(
              labelText: 'Account name',
              hintText: 'Savings, FDR, bKash',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                v == null || v.trim().isEmpty ? 'Enter a name' : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: type,
            decoration: const InputDecoration(
              labelText: 'Type',
              border: OutlineInputBorder(),
            ),
            items: types
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => type = v!),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: opening,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Opening balance',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                double.tryParse((v ?? '').replaceAll(',', '')) == null
                ? 'Enter an amount'
                : null,
          ),
          ListTile(
            title: const Text('Opening balance date'),
            subtitle: Text(DateHelper.formatDate(date)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          TextFormField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          SwitchListTile(
            title: const Text('Include in net worth'),
            value: include,
            onChanged: (v) => setState(() => include = v),
          ),
          if (widget.account != null)
            SwitchListTile(
              title: const Text('Archived'),
              value: archived,
              onChanged: (v) => setState(() => archived = v),
            ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save Account'),
          ),
        ],
      ),
    ),
  );
}
