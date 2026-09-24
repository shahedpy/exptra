import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../bank/bank_controller.dart';
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
  final opening = TextEditingController(text: '0');
  final note = TextEditingController();
  String type = 'Savings';
  String? selectedBank;
  DateTime date = DateTime.now();
  bool include = true, archived = false, saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      selectedBank = a.institutionName.isEmpty ? null : a.institutionName;
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
        institutionName: selectedBank ?? '',
        name: widget.account?.name ?? type,
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
          Obx(() {
            final bankController = Get.find<BankController>();
            final bankNames = bankController.banks
                .map((bank) => bank.name)
                .toList();
            if (selectedBank != null &&
                selectedBank!.isNotEmpty &&
                !bankNames.contains(selectedBank)) {
              bankNames.insert(0, selectedBank!);
            }
            return DropdownButtonFormField<String>(
              initialValue: selectedBank,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Bank',
                helperText: bankNames.isEmpty ? 'Add banks from More' : null,
                border: const OutlineInputBorder(),
              ),
              items: bankNames
                  .map(
                    (bank) => DropdownMenuItem<String>(
                      value: bank,
                      child: Text(bank),
                    ),
                  )
                  .toList(),
              onChanged: bankNames.isEmpty
                  ? null
                  : (value) => setState(() => selectedBank = value),
              validator: (value) => value == null
                  ? bankNames.isEmpty
                        ? 'Add a bank from More first'
                        : 'Select a bank'
                  : null,
            );
          }),
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
