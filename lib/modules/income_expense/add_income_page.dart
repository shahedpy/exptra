import 'package:flutter/material.dart';
import '../../core/widgets/app_ui.dart';
import 'package:get/get.dart';
import '../accounts/account_selector.dart';

import '../../core/utils/helpers.dart';
import '../../core/db/app_database.dart';
import '../../core/routes/app_routes.dart';
import '../income_source/income_source_controller.dart';
import 'income_controller.dart';

class AddIncomePage extends StatefulWidget {
  const AddIncomePage({super.key});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final incomeController = Get.find<IncomeController>();
  late final incomeSourceController = Get.find<IncomeSourceController>();

  String? _selectedSourceId;
  late DateTime _selectedDate;
  bool _isEdit = false;
  String? _editingId;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedSourceId = incomeSourceController.incomeSources.isNotEmpty
        ? incomeSourceController.incomeSources.first.id
        : null;
    final args = Get.arguments;
    if (args != null && args is Income) {
      _isEdit = true;
      _editingId = args.id;
      _accountId = args.accountId;
      _selectedDate = args.incomeDate;
      _selectedSourceId = args.sourceId;
      _amountController.text = args.amount.toString();
      _noteController.text = args.note ?? '';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_isEdit ? 'Edit Income' : 'Add Income')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppAmountField(controller: _amountController, prominent: true),
          const SizedBox(height: 16),
          Obx(() {
            final items = incomeSourceController.incomeSources;
            final selected = items.any((x) => x.id == _selectedSourceId)
                ? _selectedSourceId
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(selected),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Income Source'),
                  items: items
                      .map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text(x.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedSourceId = v),
                  validator: (v) =>
                      v == null ? 'Select an income source' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.incomeSources),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add income source'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          AccountSelector(
            value: _accountId,
            label: 'Receive Into',
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
              child: Text(_isEdit ? 'Update Income' : 'Save Income'),
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

    if (_selectedSourceId == null) {
      Get.snackbar('Error', 'Please select an income source');
      return;
    }

    final amount = CurrencyHelper.parseAmount(_amountController.text);

    final sourceName = incomeSourceController
        .getIncomeSourceById(_selectedSourceId!)
        ?.name;

    if (_isEdit && _editingId != null) {
      incomeController.updateIncome(
        id: _editingId!,
        amount: amount,
        accountId: _accountId,
        sourceId: _selectedSourceId,
        source: sourceName,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      Get.back();
      Get.snackbar('Success', 'Income updated successfully');
      return;
    }

    incomeController.addIncome(
      amount: amount,
      accountId: _accountId,
      sourceId: _selectedSourceId,
      source: sourceName,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Income added successfully');
  }
}
