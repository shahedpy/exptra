import 'package:flutter/material.dart';
import '../../core/widgets/app_ui.dart';
import 'package:get/get.dart';
import '../accounts/account_selector.dart';
import 'expense_controller.dart';
import '../expense_category/expense_category_controller.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../core/routes/app_routes.dart';

class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  late final expenseController = Get.find<ExpenseController>();
  late final categoryController = Get.find<ExpenseCategoryController>();

  late String? _selectedCategoryId;
  late DateTime _selectedDate;
  bool _isEdit = false;
  String? _editingId;
  String? _accountId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedCategoryId = categoryController.categories.isNotEmpty
        ? categoryController.categories.first.id
        : null;
    final args = Get.arguments;
    if (args != null && args is Expense) {
      _isEdit = true;
      _editingId = args.id;
      _accountId = args.accountId;
      _selectedDate = args.expenseDate;
      _selectedCategoryId = args.categoryId;
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
    appBar: AppBar(title: Text(_isEdit ? 'Edit Expense' : 'Add Expense')),
    body: Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppAmountField(controller: _amountController, prominent: true),
          const SizedBox(height: 16),
          Obx(() {
            final items = categoryController.categories;
            final selected = items.any((x) => x.id == _selectedCategoryId)
                ? _selectedCategoryId
                : null;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(selected),
                  initialValue: selected,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Expense Category',
                  ),
                  items: items
                      .map(
                        (x) => DropdownMenuItem(
                          value: x.id,
                          child: Text(x.name, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _selectedCategoryId = v),
                  validator: (v) =>
                      v == null ? 'Select an expense category' : null,
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => Get.toNamed(AppRoutes.expenseCategories),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Add expense category'),
                  ),
                ),
              ],
            );
          }),
          const SizedBox(height: 16),
          AccountSelector(
            value: _accountId,
            label: 'Paid From',
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
              child: Text(_isEdit ? 'Update Expense' : 'Save Expense'),
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

    if (_selectedCategoryId == null) {
      Get.snackbar('Error', 'Please select an expense category');
      return;
    }

    final amount = CurrencyHelper.parseAmount(_amountController.text);

    if (_isEdit && _editingId != null) {
      expenseController.updateExpense(
        id: _editingId!,
        categoryId: _selectedCategoryId!,
        amount: amount,
        accountId: _accountId,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      Get.back();
      Get.snackbar('Success', 'Expense updated successfully');
      return;
    }

    expenseController.addExpense(
      categoryId: _selectedCategoryId!,
      amount: amount,
      accountId: _accountId,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Expense added successfully');
  }
}
