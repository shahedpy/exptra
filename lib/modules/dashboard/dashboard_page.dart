import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../expense/expense_controller.dart';
import '../income/income_controller.dart';
import '../category/category_controller.dart';
import 'dashboard_controller.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final incomeController = Get.find<IncomeController>();
    final categoryController = Get.find<CategoryController>();
    final dashboardController = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(title: const Text('Exptra'), elevation: 0),
      body: Obx(
        () =>
            expenseController.expenses.isEmpty &&
                incomeController.incomes.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCard(dashboardController),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildIncomesSection(incomeController),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildExpensesSection(
                      expenseController,
                      categoryController,
                    ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEntrySheet,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddEntrySheet() {
    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(Get.context!).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.remove_circle_outline),
                title: const Text('Add Expense'),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.addExpense);
                },
              ),
              ListTile(
                leading: const Icon(Icons.add_circle_outline),
                title: const Text('Add Income'),
                onTap: () {
                  Get.back();
                  Get.toNamed(AppRoutes.addIncome);
                },
              ),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
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
            'No entries yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first income or expense to get started',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
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
              'Current Balance',
              style: Theme.of(
                Get.context!,
              ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              dashboardController.getFormattedBalance(),
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
                  'Income',
                  dashboardController.getFormattedIncome(),
                ),
                _buildStatItem(
                  'Expense',
                  dashboardController.getFormattedExpense(),
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

  Widget _buildExpensesSection(
    ExpenseController expenseController,
    CategoryController categoryController,
  ) {
    return Obx(() {
      if (expenseController.expenses.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                'No expenses yet. Use + to add expense or income.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        );
      }

      return _buildExpensesList(expenseController, categoryController);
    });
  }

  Widget _buildIncomesSection(IncomeController incomeController) {
    return Obx(() {
      if (incomeController.incomes.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                'No incomes yet. Use + to add expense or income.',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        );
      }

      return _buildIncomesList(incomeController);
    });
  }

  Widget _buildIncomesList(IncomeController incomeController) {
    return Obx(
      () => ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.defaultPadding,
        ),
        itemCount: incomeController.incomes.length,
        itemBuilder: (_, index) {
          final income = incomeController.incomes[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onLongPress: () {
                Get.dialog(
                  AlertDialog(
                    title: const Text('Delete Income'),
                    content: const Text(
                      'Are you sure you want to delete this income?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Get.back(),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          incomeController.deleteIncome(income.id);
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
                leading: const CircleAvatar(
                  backgroundColor: Colors.green,
                  child: Icon(Icons.add_card, color: Colors.white),
                ),
                title: Text(
                  income.source != null && income.source!.isNotEmpty
                      ? income.source!
                      : 'Income',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (income.note != null && income.note!.isNotEmpty)
                      Text(
                        income.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      DateHelper.formatDate(income.incomeDate),
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
                      CurrencyHelper.formatAmount(income.amount),
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
