import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import 'expense_controller.dart';
import 'income_controller.dart';
import '../category/category_controller.dart';

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});

  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  int _selectedIndex = 0; // 0 = All, 1 = Income, 2 = Expense

  @override
  Widget build(BuildContext context) {
    final incomeController = Get.find<IncomeController>();
    final expenseController = Get.find<ExpenseController>();
    final categoryController = Get.find<CategoryController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Income & Expense')),
      body: Column(
        children: [
          // Button Segment
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 12,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt_rounded),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Income'),
                  icon: Icon(Icons.trending_up_rounded),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Expense'),
                  icon: Icon(Icons.trending_down_rounded),
                ),
              ],
              selected: {_selectedIndex},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedIndex = selected.first;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: _selectedIndex == 0
                ? Obx(() {
                    // Build a unified list: tag each item with its type and date
                    final allItems = [
                      ...incomeController.incomes.map(
                        (e) => _TransactionItem(
                          isIncome: true,
                          date: e.incomeDate,
                          title: e.source ?? 'Income',
                          note: e.note,
                          amount: e.amount,
                          id: e.id,
                        ),
                      ),
                      ...expenseController.expenses.map((e) {
                        final cat = categoryController.getCategoryById(
                          e.categoryId,
                        );
                        return _TransactionItem(
                          isIncome: false,
                          date: e.expenseDate,
                          title: cat?.name ?? 'Expense',
                          note: e.note,
                          amount: e.amount,
                          id: e.id,
                        );
                      }),
                    ]..sort((a, b) => b.date.compareTo(a.date));

                    if (allItems.isEmpty) {
                      return Center(
                        child: Text(
                          'No transactions yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      itemCount: allItems.length,
                      itemBuilder: (_, index) {
                        final item = allItems[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () {
                              final orig = item.isIncome
                                  ? incomeController.incomes.firstWhere(
                                      (e) => e.id == item.id,
                                    )
                                  : expenseController.expenses.firstWhere(
                                      (e) => e.id == item.id,
                                    );
                              if (item.isIncome) {
                                Get.toNamed(
                                  AppRoutes.addIncome,
                                  arguments: orig,
                                );
                              } else {
                                Get.toNamed(
                                  AppRoutes.addExpense,
                                  arguments: orig,
                                );
                              }
                            },
                            onLongPress: () {
                              Get.dialog(
                                AlertDialog(
                                  title: Text(
                                    'Delete ${item.isIncome ? 'Income' : 'Expense'}',
                                  ),
                                  content: Text(
                                    'Are you sure you want to delete this ${item.isIncome ? 'income' : 'expense'} entry?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Get.back(),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        if (item.isIncome) {
                                          incomeController.deleteIncome(
                                            item.id,
                                          );
                                        } else {
                                          expenseController.deleteExpense(
                                            item.id,
                                          );
                                        }
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
                                backgroundColor: item.isIncome
                                    ? Colors.green
                                    : Colors.red,
                                child: Icon(
                                  item.isIncome
                                      ? Icons.add_circle_rounded
                                      : Icons.remove_circle_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(item.title),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.isIncome ? 'Income' : 'Expense',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  if (item.note != null &&
                                      item.note!.isNotEmpty)
                                    Text(
                                      item.note!,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  Text(
                                    DateHelper.formatDate(item.date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Text(
                                CurrencyHelper.formatAmount(item.amount),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: item.isIncome
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  })
                : _selectedIndex == 1
                // Income List
                ? Obx(() {
                    if (incomeController.incomes.isEmpty) {
                      return Center(
                        child: Text(
                          'No income entries yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      itemCount: incomeController.incomes.length,
                      itemBuilder: (_, index) {
                        final entry = incomeController.incomes[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.addIncome,
                              arguments: entry,
                            ),
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
                              leading: const CircleAvatar(
                                backgroundColor: Colors.green,
                                child: Icon(
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
                                  if (entry.note != null &&
                                      entry.note!.isNotEmpty)
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
                  })
                : Obx(() {
                    if (expenseController.expenses.isEmpty) {
                      return Center(
                        child: Text(
                          'No expense entries yet',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(
                        AppConstants.defaultPadding,
                      ),
                      itemCount: expenseController.expenses.length,
                      itemBuilder: (_, index) {
                        final entry = expenseController.expenses[index];

                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: InkWell(
                            onTap: () => Get.toNamed(
                              AppRoutes.addExpense,
                              arguments: entry,
                            ),
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
                                        expenseController.deleteExpense(
                                          entry.id,
                                        );
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
                                backgroundColor: Colors.red,
                                child: Icon(
                                  Icons.remove_circle_rounded,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                categoryController
                                        .getCategoryById(entry.categoryId)
                                        ?.name ??
                                    'Expense',
                              ),
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
                                  if (entry.note != null &&
                                      entry.note!.isNotEmpty)
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
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Drag handle
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Text(
                  'Add Entry',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('Add Income'),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.green,
                    child: Icon(Icons.trending_up_rounded, color: Colors.white),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.addIncome);
                  },
                ),
                ListTile(
                  title: const Text('Add Expense'),
                  leading: const CircleAvatar(
                    backgroundColor: Colors.red,
                    child: Icon(
                      Icons.trending_down_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    Get.toNamed(AppRoutes.addExpense);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _TransactionItem {
  final bool isIncome;
  final DateTime date;
  final String title;
  final String? note;
  final double amount;
  final String id;

  _TransactionItem({
    required this.isIncome,
    required this.date,
    required this.title,
    required this.note,
    required this.amount,
    required this.id,
  });
}
