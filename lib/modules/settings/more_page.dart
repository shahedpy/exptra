import '../accounts/account_controller.dart';
import '../bank/bank_controller.dart';
import '../account_type/account_type_controller.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          _section(context, 'Insights', [
            _item(
              context,
              Icons.bar_chart_rounded,
              'Reports',
              'Financial insights and history',
              () => Get.to(() => const ReportPage()),
            ),
          ]),
          const SizedBox(height: 20),
          _section(context, 'Management', [
            _item(
              context,
              Icons.category_outlined,
              'Expense Categories',
              'Values used when adding expenses',
              () => Get.toNamed(AppRoutes.expenseCategories),
            ),
            _item(
              context,
              Icons.payments_outlined,
              'Income Sources',
              'Values used when adding income',
              () => Get.toNamed(AppRoutes.incomeSources),
            ),
            _item(
              context,
              Icons.account_balance_outlined,
              'Banks',
              'Institutions used by accounts',
              () => Get.toNamed(AppRoutes.banks),
            ),
            _item(
              context,
              Icons.account_tree_outlined,
              'Account Types',
              'Types used when adding accounts',
              () => Get.toNamed(AppRoutes.accountTypes),
            ),
          ]),
          const SizedBox(height: 20),
          _section(context, 'Data', [
            _item(
              context,
              Icons.backup_outlined,
              'Backup data',
              'Export your EXPTRA data',
              _backupData,
            ),
            _item(
              context,
              Icons.restore_outlined,
              'Restore data',
              'Import a saved backup',
              _restoreData,
            ),
          ]),
          const SizedBox(height: 20),
          Text(
            'About',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            elevation: 0,
            child: Column(
              children: [
                const ListTile(
                  leading: Icon(Icons.person_outline),
                  title: Text('Concept • Code • Design'),
                  subtitle: Text('Shahed Mohammad Hridoy'),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('App Version'),
                  subtitle: FutureBuilder<PackageInfo>(
                    future: _packageInfoFuture,
                    builder: (_, snapshot) => Text(
                      snapshot.hasData ? snapshot.data!.version : 'Unavailable',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, List<Widget> items) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Card(
          color: theme.colorScheme.surfaceContainerLow,
          elevation: 0,
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, indent: 56),
                items[i],
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _item(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback action,
  ) => ListTile(
    leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: action,
  );

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
      if (Get.isRegistered<AccountController>()) {
        await Get.find<AccountController>().reload();
      }
      if (Get.isRegistered<BankController>()) {
        await Get.find<BankController>().loadBanks();
      }
      if (Get.isRegistered<AccountTypeController>()) {
        await Get.find<AccountTypeController>().load();
      }

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
