import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/app_database.dart';
import '../../core/db/database_backup_service.dart';
import '../category/category_controller.dart';
import '../expense/expense_controller.dart';
import '../income/income_controller.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.backup_outlined),
            title: const Text('Backup data'),
            subtitle: const Text('Export your local data file'),
            onTap: _backupData,
          ),
          ListTile(
            leading: const Icon(Icons.restore_outlined),
            title: const Text('Restore data'),
            subtitle: const Text('Import data from a backup file'),
            onTap: _restoreData,
          ),
        ],
      ),
    );
  }

  Future<void> _backupData() async {
    try {
      final backupService = DatabaseBackupService();
      final db = Get.find<AppDatabase>();
      final backupFile = await backupService.createBackupFile(db);

      await SharePlus.instance.share(
        ShareParams(files: [XFile(backupFile.path)]),
      );

      Get.snackbar(
        'Backup Ready',
        'Save the shared file to cloud or device storage.',
      );
    } catch (e) {
      Get.snackbar('Backup Failed', 'Could not create backup: $e');
    }
  }

  Future<void> _restoreData() async {
    try {
      final selectedFile = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['exptra'],
      );

      final backupPath = selectedFile?.files.single.path;
      if (backupPath == null) {
        return;
      }

      final confirmed = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('Restore Backup'),
          content: const Text(
            'Current local data will be replaced with backup data. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Restore'),
            ),
          ],
        ),
      );

      if (confirmed != true) {
        return;
      }

      final backupService = DatabaseBackupService();
      final db = Get.find<AppDatabase>();
      await backupService.restoreBackupFromPath(
        backupPath: backupPath,
        database: db,
      );

      final categoryController = _resolveCategoryController();
      final expenseController = _resolveExpenseController();
      final incomeController = _resolveIncomeController();

      await categoryController.loadCategories();
      await expenseController.loadExpenses();
      await incomeController.loadIncomes();

      Get.snackbar('Restore Complete', 'Data restored from backup file.');
    } catch (e) {
      Get.snackbar('Restore Failed', 'Could not restore backup: $e');
    }
  }

  CategoryController _resolveCategoryController() {
    if (Get.isRegistered<CategoryController>()) {
      return Get.find<CategoryController>();
    }
    return Get.put(CategoryController());
  }

  ExpenseController _resolveExpenseController() {
    if (Get.isRegistered<ExpenseController>()) {
      return Get.find<ExpenseController>();
    }
    return Get.put(ExpenseController());
  }

  IncomeController _resolveIncomeController() {
    if (Get.isRegistered<IncomeController>()) {
      return Get.find<IncomeController>();
    }
    return Get.put(IncomeController());
  }
}
