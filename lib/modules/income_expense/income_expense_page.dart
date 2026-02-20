import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import 'expense_controller.dart';
import 'income_controller.dart';

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomeController = Get.find<IncomeController>();
    final expenseController = Get.find<ExpenseController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Income & Expense'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Income', icon: Icon(Icons.trending_up_rounded)),
            Tab(text: 'Expense', icon: Icon(Icons.trending_down_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Income Tab
          Obx(() {
            if (incomeController.incomes.isEmpty) {
              return Center(
                child: Text(
                  'No income entries yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: incomeController.incomes.length,
              itemBuilder: (_, index) {
                final entry = incomeController.incomes[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onLongPress: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Income'),
                          content: const Text(
                            'Are you sure you want to delete this income entry?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                incomeController.deleteIncome(entry.id);
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
                        backgroundColor: Colors.green,
                        child: const Icon(
                          Icons.add_circle_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(entry.source ?? 'Income'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty)
                            Text(
                              entry.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            DateHelper.formatDate(entry.incomeDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        CurrencyHelper.formatAmount(entry.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),

          // Expense Tab
          Obx(() {
            if (expenseController.expenses.isEmpty) {
              return Center(
                child: Text(
                  'No expense entries yet',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              itemCount: expenseController.expenses.length,
              itemBuilder: (_, index) {
                final entry = expenseController.expenses[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    onLongPress: () {
                      Get.dialog(
                        AlertDialog(
                          title: const Text('Delete Expense'),
                          content: const Text(
                            'Are you sure you want to delete this expense entry?',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                expenseController.deleteExpense(entry.id);
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
                        backgroundColor: Colors.red,
                        child: const Icon(
                          Icons.remove_circle_rounded,
                          color: Colors.white,
                        ),
                      ),
                      title: Text(entry.categoryId),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expense',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          if (entry.note != null && entry.note!.isNotEmpty)
                            Text(
                              entry.note!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          Text(
                            DateHelper.formatDate(entry.expenseDate),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                      trailing: Text(
                        CurrencyHelper.formatAmount(entry.amount),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: const Text('Add Entry'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Add Income'),
              leading: const Icon(
                Icons.trending_up_rounded,
                color: Colors.green,
              ),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.addIncome);
              },
            ),
            ListTile(
              title: const Text('Add Expense'),
              leading: const Icon(
                Icons.trending_down_rounded,
                color: Colors.red,
              ),
              onTap: () {
                Get.back();
                Get.toNamed(AppRoutes.addExpense);
              },
            ),
          ],
        ),
      ),
    );
  }
}
