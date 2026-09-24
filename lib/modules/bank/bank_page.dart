import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Banks')),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : controller.banks.isEmpty
            ? const Center(child: Text('Add a bank to use it in accounts.'))
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                buildDefaultDragHandles: false,
                itemCount: controller.banks.length,
                onReorderItem: controller.reorderBanks,
                itemBuilder: (context, index) {
                  final bank = controller.banks[index];
                  return Card(
                    key: ValueKey(bank.id),
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_outlined),
                      title: Text(bank.name),
                      onTap: () => _editBank(bank),
                      onLongPress: () => _confirmDelete(bank),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8),
                          child: Icon(Icons.drag_handle),
                        ),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addBank,
        child: const Icon(Icons.add),
      ),
    );
  }

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
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
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
