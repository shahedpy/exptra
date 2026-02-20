import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/app_database.dart';
import '../../core/db/database_backup_service.dart';
import '../../core/routes/app_routes.dart';
import '../reports/report_page.dart';
import '../expense_category/expense_category_controller.dart';
import '../income_source/income_source_controller.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';

class MorePage extends StatefulWidget {
  const MorePage({super.key});

  @override
  State<MorePage> createState() => _MorePageState();
}

class _MorePageState extends State<MorePage> {
  late final Future<PackageInfo> _packageInfoFuture;

  @override
  void initState() {
    super.initState();
    _packageInfoFuture = PackageInfo.fromPlatform();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.bar_chart_rounded),
            title: const Text('Reports'),
            subtitle: const Text('View income and expense reports'),
            onTap: () => Get.to(() => const ReportPage()),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('Expense Categories'),
            subtitle: const Text('Manage expense category list'),
            onTap: () => Get.toNamed(AppRoutes.expenseCategories),
          ),
          ListTile(
            leading: const Icon(Icons.account_balance_wallet_outlined),
            title: const Text('Income Sources'),
            subtitle: const Text('Manage income source list'),
            onTap: () => Get.toNamed(AppRoutes.incomeSources),
          ),
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
          const Divider(height: 1),
          const ListTile(
            leading: Icon(Icons.person_outline),
            title: Text('Concept • Code • Design'),
            subtitle: Text('Shahed Mohammad Hridoy'),
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('App Version'),
            subtitle: FutureBuilder<PackageInfo>(
              future: _packageInfoFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Text('Loading...');
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Text('Unavailable');
                }

                final packageInfo = snapshot.data!;
                return Text(packageInfo.version);
              },
            ),
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
      final incomeSourceController = _resolveIncomeSourceController();
      final expenseController = _resolveExpenseController();
      final incomeController = _resolveIncomeController();
      final lendBorrowController = _resolveLendBorrowController();

      await categoryController.loadCategories();
      await incomeSourceController.loadIncomeSources();
      await expenseController.loadExpenses();
      await incomeController.loadIncomes();
      await lendBorrowController.loadEntries();

      Get.snackbar('Restore Complete', 'Data restored from backup file.');
    } catch (e) {
      Get.snackbar('Restore Failed', 'Could not restore backup: $e');
    }
  }

  ExpenseCategoryController _resolveCategoryController() {
    if (Get.isRegistered<ExpenseCategoryController>()) {
      return Get.find<ExpenseCategoryController>();
    }
    return Get.put(ExpenseCategoryController());
  }

  IncomeSourceController _resolveIncomeSourceController() {
    if (Get.isRegistered<IncomeSourceController>()) {
      return Get.find<IncomeSourceController>();
    }
    return Get.put(IncomeSourceController());
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

  LendBorrowController _resolveLendBorrowController() {
    if (Get.isRegistered<LendBorrowController>()) {
      return Get.find<LendBorrowController>();
    }
    return Get.put(LendBorrowController());
  }
}
