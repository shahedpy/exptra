import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Income' : 'Add Income'),
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
                'Income Source',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Obx(() {
                final sources = incomeSourceController.incomeSources;
                if (sources.isEmpty) {
                  return Center(
                    child: Column(
                      children: [
                        const Text('No income sources found'),
                        const SizedBox(height: 8),
                        ElevatedButton(
                          onPressed: () => Get.toNamed(AppRoutes.incomeSources),
                          child: const Text('Add Income Source'),
                        ),
                      ],
                    ),
                  );
                }

                if (_selectedSourceId == null && sources.isNotEmpty) {
                  _selectedSourceId = sources.first.id;
                }

                return DropdownButtonFormField<String>(
                  initialValue: _selectedSourceId,
                  items: sources.map((source) {
                    return DropdownMenuItem(
                      value: source.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: ColorHelper.getColorFromInt(
                              source.color,
                            ),
                            radius: 16,
                          ),
                          const SizedBox(width: 12),
                          Text(source.name),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedSourceId = value;
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
              }),
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
                  child: Text(_isEdit ? 'Update Income' : 'Add Income'),
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

    if (_selectedSourceId == null) {
      Get.snackbar('Error', 'Please select an income source');
      return;
    }

    final amount = double.parse(
      _amountController.text.replaceAll(AppConstants.currencySymbol, ''),
    );

    final sourceName = incomeSourceController
        .getIncomeSourceById(_selectedSourceId!)
        ?.name;

    if (_isEdit && _editingId != null) {
      incomeController.updateIncome(
        id: _editingId!,
        amount: amount,
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
      sourceId: _selectedSourceId,
      source: sourceName,
      note: _noteController.text.trim(),
      date: _selectedDate,
    );

    Get.back();
    Get.snackbar('Success', 'Income added successfully');
  }
}
