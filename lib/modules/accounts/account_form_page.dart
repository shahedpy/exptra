import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../bank/bank_controller.dart';
import '../../core/routes/app_routes.dart';
import '../../core/widgets/app_ui.dart';
import 'account_controller.dart';
import '../account_type/account_type_controller.dart';
import '../account_type/account_type_form_page.dart';

class AccountFormPage extends StatefulWidget {
  final Account? account;
  const AccountFormPage({super.key, this.account});
  @override
  State<AccountFormPage> createState() => _AccountFormPageState();
}

class _AccountFormPageState extends State<AccountFormPage> {
  final key = GlobalKey<FormState>();
  final opening = TextEditingController(text: '0');
  final name = TextEditingController();
  final note = TextEditingController();
  String? selectedTypeId;
  String? selectedBank;
  DateTime date = DateTime.now();
  bool include = true, archived = false, saving = false;

  @override
  void initState() {
    super.initState();
    final a = widget.account;
    if (a != null) {
      selectedBank = a.institutionName.isEmpty ? null : a.institutionName;
      name.text = a.name;
      opening.text = a.openingBalance.toStringAsFixed(2);
      note.text = a.note ?? '';
      selectedTypeId = a.accountTypeId;
      date = a.openingBalanceDate;
      include = a.includeInNetWorth;
      archived = a.isArchived;
    }
  }

  @override
  void dispose() {
    opening.dispose();
    name.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate() || saving) return;
    final typeController = Get.find<AccountTypeController>();
    final effectiveTypeId =
        selectedTypeId ?? typeController.types.firstOrNull?.id;
    final selectedType = typeController.types
        .where((t) => t.id == effectiveTypeId)
        .firstOrNull;
    if (selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add an account type first.')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final controller = Get.find<AccountController>();
      await controller.repository.saveAccount(
        id: widget.account?.id,
        institutionName: selectedBank ?? '',
        name: name.text.trim(),
        type: selectedType.name,
        accountTypeId: selectedType.id,
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
            controller: name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Account Name',
              hintText: 'e.g., Savings Account',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Account name is required'
                : null,
          ),
          const SizedBox(height: 16),
          Obx(() {
            final bankController = Get.find<BankController>();
            final types = Get.find<AccountTypeController>().types;
            final effectiveTypeId = selectedTypeId ?? types.firstOrNull?.id;
            final selectedType = types
                .where((t) => t.id == effectiveTypeId)
                .firstOrNull;
            final bankNames = bankController.banks
                .map((bank) => bank.name)
                .toList();
            if (selectedBank != null &&
                selectedBank!.isNotEmpty &&
                !bankNames.contains(selectedBank)) {
              bankNames.insert(0, selectedBank!);
            }
            return DropdownButtonFormField<String>(
              key: ValueKey(selectedBank),
              initialValue: selectedBank,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Bank / Institution',
                helperText: selectedType?.requiresInstitution == false
                    ? 'Optional for this account type'
                    : null,
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
              validator: (value) =>
                  value == null && (selectedType?.requiresInstitution ?? true)
                  ? 'Select a bank'
                  : null,
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => Get.toNamed(AppRoutes.banks),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add bank'),
            ),
          ),
          const SizedBox(height: 8),
          Obx(() {
            final types = Get.find<AccountTypeController>().types;
            final effectiveTypeId = selectedTypeId ?? types.firstOrNull?.id;
            return DropdownButtonFormField<String>(
              key: ValueKey(effectiveTypeId),
              initialValue: effectiveTypeId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Account Type'),
              items: types
                  .map(
                    (t) => DropdownMenuItem(
                      value: t.id,
                      child: Text(t.name, overflow: TextOverflow.ellipsis),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedTypeId = v),
              validator: (v) => v == null ? 'Select an account type' : null,
            );
          }),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final createdId = await Get.to<String>(
                  () => const AccountTypeFormPage(),
                );
                if (mounted && createdId != null) {
                  setState(() => selectedTypeId = createdId);
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Add account type'),
            ),
          ),
          const SizedBox(height: 16),
          AppAmountField(
            controller: opening,
            label: 'Opening Balance',
            validator: (v) =>
                double.tryParse((v ?? '').replaceAll(',', '')) == null
                ? 'Enter an amount'
                : null,
          ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'Balance As Of',
            date: date,
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
          const SizedBox(height: 16),
          const InputDecorator(
            decoration: InputDecoration(labelText: 'Currency'),
            child: Text('BDT'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: note,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
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
          const SizedBox(height: 24),
          FilledButton(
            onPressed: saving ? null : save,
            child: Text(saving ? 'Saving…' : 'Save Account'),
          ),
        ],
      ),
    ),
  );
}
