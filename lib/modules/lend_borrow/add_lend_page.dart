import 'package:flutter/material.dart';
import '../../core/widgets/app_ui.dart';
import 'package:get/get.dart';
import '../accounts/account_selector.dart';

import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import 'lend_borrow_controller.dart';

class AddLendPage extends StatefulWidget {
  const AddLendPage({super.key});

  @override
  State<AddLendPage> createState() => _AddLendPageState();
}

class _AddLendPageState extends State<AddLendPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late final LendBorrowController controller = Get.find<LendBorrowController>();

  late DateTime _selectedDate;
  bool _isEdit = false;
  String? _editingId;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    final args = Get.arguments;
    if (args != null && args is Lend) {
      _isEdit = true;
      _editingId = args.id;
      _accountId = args.accountId;
      _selectedDate = args.lendDate;
      _nameController.text = args.personName;
      _amountController.text = args.amount.toString();
      _noteController.text = args.note ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEdit ? 'Edit Lend' : 'Add Lend')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Card(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                'Lending moves money from your account into money to receive.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Person',
              hintText: 'Name',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Person name is required'
                : null,
          ),
          const SizedBox(height: 16),
          AppAmountField(controller: _amountController, prominent: true),
          const SizedBox(height: 16),
          AccountSelector(
            value: _accountId,
            label: 'From Account',
            onChanged: (v) => setState(() => _accountId = v),
          ),
          const SizedBox(height: 16),
          AppDateField(label: 'Date', date: _selectedDate, onTap: _pickDate),
          const SizedBox(height: 16),
          TextFormField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
            validator: ValidationHelper.validateNote,
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              onPressed: _submitForm,
              child: Text(_isEdit ? 'Update Lend' : 'Save Lend'),
            ),
          ),
        ],
      ),
    ),
  );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitForm() {
    if (!_formKey.currentState!.validate()) return;

    final amount = CurrencyHelper.parseAmount(_amountController.text);

    if (_isEdit && _editingId != null) {
      controller.updateEntry(
        id: _editingId!,
        personName: _nameController.text.trim(),
        amount: amount,
        accountId: _accountId,
        type: LendBorrowController.typeLend,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      Get.back();
      Get.snackbar('Success', 'Lend updated successfully');
      return;
    }

    controller.addEntry(
      personName: _nameController.text.trim(),
      amount: amount,
      accountId: _accountId,
      type: LendBorrowController.typeLend,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Lend added successfully');
  }
}
