import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'expense_controller.dart';
import '../category/category_controller.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_constants.dart';

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
  late final categoryController = Get.find<CategoryController>();

  late String? _selectedCategoryId;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedCategoryId =
        categoryController.categories.isNotEmpty
            ? categoryController.categories.first.id
            : null;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Amount',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  prefixText: AppConstants.currencySymbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
                validator: ValidationHelper.validateAmount,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              const Text(
                'Category',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Obx(
                () {
                  final categories = categoryController.categories;
                  if (categories.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          const Text('No categories found'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Get.toNamed('/categories'),
                            child: const Text('Add Category'),
                          ),
                        ],
                      ),
                    );
                  }

                  return DropdownButtonFormField<String>(
                    initialValue: _selectedCategoryId,
                    items: categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat.id,
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor:
                                  ColorHelper.getColorFromInt(cat.color),
                              radius: 16,
                            ),
                            const SizedBox(width: 12),
                            Text(cat.name),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(
                          AppConstants.defaultBorderRadius,
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              const Text(
                'Date',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                trailing: const Icon(Icons.calendar_today),
                title: Text(DateHelper.formatDate(_selectedDate)),
                onTap: _pickDate,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
              const Text(
                'Note (Optional)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _noteController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Add notes...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
                validator: ValidationHelper.validateNote,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 2),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text('Add Expense'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
      Get.snackbar('Error', 'Please select a category');
      return;
    }

    final amount =
        double.parse(_amountController.text.replaceAll(AppConstants.currencySymbol, ''));

    expenseController.addExpense(
      categoryId: _selectedCategoryId!,
      amount: amount,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Expense added successfully');
  }
}


