import 'package:flutter/material.dart';
import '../../core/widgets/master_data_list.dart';
import 'package:get/get.dart';

import '../../core/db/app_database.dart';
import 'bank_controller.dart';

class BankPage extends StatefulWidget {
  const BankPage({super.key});

  @override
  State<BankPage> createState() => _BankPageState();
}

class _BankPageState extends State<BankPage> {
  final controller = Get.find<BankController>();
  final nameController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => MasterDataList<Bank>(
      title: 'Banks',
      singular: 'Bank',
      emptyMessage: 'No banks added yet. Add one to use in accounts.',
      icon: Icons.account_balance_outlined,
      items: controller.banks.toList(),
      loading: controller.isLoading.value,
      idOf: (x) => x.id,
      nameOf: (x) => x.name,

      onAdd: _addBank,
      onEdit: _editBank,
      onDelete: _confirmDelete,
      onReorder: controller.reorderBanks,
    ),
  );

  void _addBank() {
    nameController.clear();
    _showBankDialog('Add Bank');
  }

  void _editBank(Bank bank) {
    nameController.text = bank.name;
    _showBankDialog('Edit Bank', bank: bank);
  }

  void _confirmDelete(Bank bank) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Bank'),
        content: Text('Are you sure you want to delete "${bank.name}"?'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteBank(bank);
              Get.back();
            },
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showBankDialog(String title, {Bank? bank}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: nameController,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Bank name',
            hintText: 'e.g., City Bank, bKash',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => _saveBank(bank),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _saveBank(bank),
            child: Text(bank == null ? 'Add' : 'Update'),
          ),
        ],
      ),
    );
  }

  void _saveBank(Bank? bank) {
    final name = nameController.text.trim();
    if (name.isEmpty) {
      Get.snackbar('Error', 'Bank name is required');
      return;
    }
    if (bank == null) {
      controller.addBank(name);
    } else {
      controller.updateBank(id: bank.id, name: name);
    }
    Navigator.pop(context);
  }
}
