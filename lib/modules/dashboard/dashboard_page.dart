import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../expense/expense_controller.dart';
import '../category/category_controller.dart';
import 'dashboard_controller.dart';
import '../../core/db/app_database.dart';
import '../../core/db/database_backup_service.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';

enum _DataAction { backup, restore }

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.put(ExpenseController());
    final categoryController = Get.put(CategoryController());
    final dashboardController = Get.put(DashboardController());
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Exptra'),
        elevation: 0,
        actions: [
          PopupMenuButton<_DataAction>(
            icon: const Icon(Icons.more_vert),
            onSelected: (action) => _onDataActionSelected(action),
            itemBuilder: (_) => const [
              PopupMenuItem<_DataAction>(
                value: _DataAction.backup,
                child: Text('Backup data'),
              ),
              PopupMenuItem<_DataAction>(
                value: _DataAction.restore,
                child: Text('Restore data'),
              ),
            ],
          ),
        ],
      ),
      body: Obx(
        () => expenseController.expenses.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCard(dashboardController),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildExpensesList(expenseController, categoryController),
                  ],
                ),
              ),
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(bottom: bottomInset),
        child: FloatingActionButton(
          onPressed: () => Get.toNamed(AppRoutes.addExpense),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: AppConstants.defaultPadding),
          Text(
            'No expenses yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first expense to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Future<void> _onDataActionSelected(_DataAction action) async {
    switch (action) {
      case _DataAction.backup:
        await _backupData();
      case _DataAction.restore:
        await _restoreData();
    }
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

      final expenseController = Get.find<ExpenseController>();
      final categoryController = Get.find<CategoryController>();

      await categoryController.loadCategories();
      await expenseController.loadExpenses();

      Get.snackbar('Restore Complete', 'Data restored from backup file.');
    } catch (e) {
      Get.snackbar('Restore Failed', 'Could not restore backup: $e');
    }
  }

  Widget _buildSummaryCard(DashboardController dashboardController) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.all(AppConstants.defaultPadding),
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppConstants.defaultBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Expenses',
              style: Theme.of(
                Get.context!,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              dashboardController.getFormattedTotal(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Transactions',
                  dashboardController.getExpenseCount().toString(),
                ),
                _buildStatItem(
                  'Average',
                  dashboardController.getAverageExpense(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildExpensesList(
    ExpenseController expenseController,
    CategoryController categoryController,
  ) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
        ),
        itemCount: expenseController.expenses.length,
        itemBuilder: (_, index) {
          final expense = expenseController.expenses[index];
          final category = categoryController.getCategoryById(
            expense.categoryId,
          );

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onLongPress: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Delete Expense'),
                    content: const Text(
                      'Are you sure you want to delete this expense?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          expenseController.deleteExpense(expense.id);
                          Get.back();
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                );
              },
              child: ListTile(
                contentPadding: const EdgeInsets.all(
                  AppConstants.defaultPadding,
                ),
                leading: CircleAvatar(
                  backgroundColor: ColorHelper.getColorFromInt(category?.color),
                  child: Icon(Icons.category, color: Colors.white),
                ),
                title: Text(category?.name ?? 'Unknown'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (expense.note != null && expense.note!.isNotEmpty)
                      Text(
                        expense.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      DateHelper.formatDate(expense.expenseDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      CurrencyHelper.formatAmount(expense.amount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
