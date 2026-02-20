import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import 'lend_borrow_controller.dart';

class AddBorrowPage extends StatefulWidget {
  const AddBorrowPage({super.key});

  @override
  State<AddBorrowPage> createState() => _AddBorrowPageState();
}

class _AddBorrowPageState extends State<AddBorrowPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late final LendBorrowController controller = Get.find<LendBorrowController>();

  late DateTime _selectedDate;
  bool _isEdit = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();

    final args = Get.arguments;
    if (args != null && args is Borrow) {
      _isEdit = true;
      _editingId = args.id;
      _selectedDate = args.borrowDate;
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Borrow' : 'Add Borrow'),
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
                'Person Name',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter person name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                      AppConstants.defaultBorderRadius,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Person name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
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
                  child: Text(_isEdit ? 'Update Borrow' : 'Save Borrow'),
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

    final amount = double.parse(
      _amountController.text.replaceAll(AppConstants.currencySymbol, ''),
    );

    if (_isEdit && _editingId != null) {
      controller.updateEntry(
        id: _editingId!,
        personName: _nameController.text.trim(),
        amount: amount,
        type: LendBorrowController.typeBorrow,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      Get.back();
      Get.snackbar('Success', 'Borrow updated successfully');
      return;
    }

    controller.addEntry(
      personName: _nameController.text.trim(),
      amount: amount,
      type: LendBorrowController.typeBorrow,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Borrow added successfully');
  }
}
