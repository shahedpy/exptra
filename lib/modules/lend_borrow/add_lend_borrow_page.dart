import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import '../../core/db/app_database.dart';
import 'lend_borrow_controller.dart';

class AddLendBorrowPage extends StatefulWidget {
  const AddLendBorrowPage({super.key});

  @override
  State<AddLendBorrowPage> createState() => _AddLendBorrowPageState();
}

class _AddLendBorrowPageState extends State<AddLendBorrowPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  late final LendBorrowController controller = Get.find<LendBorrowController>();

  late String _selectedType;
  late DateTime _selectedDate;
  bool _isEdit = false;
  String? _editingId;

  @override
  void initState() {
    super.initState();
    _selectedType = LendBorrowController.typeLend;
    _selectedDate = DateTime.now();

    final args = Get.arguments;
    if (args != null) {
      _isEdit = true;

      if (args is Lend) {
        _editingId = args.id;
        _selectedType = LendBorrowController.typeLend;
        _selectedDate = args.lendDate;
        _nameController.text = args.personName;
        _amountController.text = args.amount.toString();
        _noteController.text = args.note ?? '';
      } else if (args is Borrow) {
        _editingId = args.id;
        _selectedType = LendBorrowController.typeBorrow;
        _selectedDate = args.borrowDate;
        _nameController.text = args.personName;
        _amountController.text = args.amount.toString();
        _noteController.text = args.note ?? '';
      }
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
        title: Text(_isEdit ? 'Edit Lend/Borrow' : 'Add Lend/Borrow'),
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
                'Type',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment<String>(
                    value: LendBorrowController.typeLend,
                    label: Text('Lend'),
                    icon: Icon(Icons.call_made_rounded),
                  ),
                  ButtonSegment<String>(
                    value: LendBorrowController.typeBorrow,
                    label: Text('Borrow'),
                    icon: Icon(Icons.call_received_rounded),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (selection) {
                  if (selection.isNotEmpty) {
                    setState(() {
                      _selectedType = selection.first;
                    });
                  }
                },
                showSelectedIcon: false,
              ),
              const SizedBox(height: AppConstants.defaultPadding * 1.5),
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
                  child: Text(_isEdit ? 'Update Entry' : 'Save Entry'),
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
        type: _selectedType,
        note: _noteController.text.trim(),
        date: _selectedDate,
      );
      Get.back();
      Get.snackbar('Success', 'Entry updated successfully');
      return;
    }

    controller.addEntry(
      personName: _nameController.text.trim(),
      amount: amount,
      type: _selectedType,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Entry added successfully');
  }
}
