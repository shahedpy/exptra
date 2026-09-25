import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_ui.dart';
import '../accounts/account_controller.dart';
import '../expense_category/expense_category_controller.dart';
import '../income_source/income_source_controller.dart';
import 'expense_controller.dart';
import 'income_controller.dart';

class IncomeExpensePage extends StatefulWidget {
  const IncomeExpensePage({super.key});
  @override
  State<IncomeExpensePage> createState() => _IncomeExpensePageState();
}

class _IncomeExpensePageState extends State<IncomeExpensePage> {
  int filter = 0;

  @override
  Widget build(BuildContext context) {
    final income = Get.find<IncomeController>();
    final expense = Get.find<ExpenseController>();
    final sources = Get.find<IncomeSourceController>();
    final categories = Get.find<ExpenseCategoryController>();
    final accounts = Get.find<AccountController>();
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Income / Expense')),
      body: Obx(() {
        final now = DateTime.now();
        final monthIncome = income.incomes
            .where(
              (x) =>
                  x.incomeDate.year == now.year &&
                  x.incomeDate.month == now.month,
            )
            .fold<double>(0, (sum, x) => sum + x.amount);
        final monthExpense = expense.expenses
            .where(
              (x) =>
                  x.expenseDate.year == now.year &&
                  x.expenseDate.month == now.month,
            )
            .fold<double>(0, (sum, x) => sum + x.amount);
        final entries = <_Entry>[
          for (final x in income.incomes)
            _Entry(
              id: x.id,
              income: true,
              amount: x.amount,
              date: x.incomeDate,
              title:
                  sources.getIncomeSourceById(x.sourceId ?? '')?.name ??
                  x.source ??
                  'Income',
              note: x.note,
              accountId: x.accountId,
            ),
          for (final x in expense.expenses)
            _Entry(
              id: x.id,
              income: false,
              amount: x.amount,
              date: x.expenseDate,
              title:
                  categories.getCategoryById(x.categoryId)?.name ?? 'Expense',
              note: x.note,
              accountId: x.accountId,
            ),
        ]..sort((a, b) => b.date.compareTo(a.date));
        final visible = entries
            .where((e) => filter == 0 || e.income == (filter == 1))
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            const AppSectionTitle('This Month'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'Income',
                    amount: monthIncome,
                    icon: Icons.add_circle_outline_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _Metric(
                    label: 'Expense',
                    amount: monthExpense,
                    icon: Icons.remove_circle_outline_rounded,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Net Cash Flow',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Flexible(
                    child: AppTrailingAmount(
                      CurrencyHelper.formatSignedAmount(
                        monthIncome - monthExpense,
                      ),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            AppActionRow(
              firstLabel: 'Add Income',
              firstIcon: Icons.add_rounded,
              onFirst: () => Get.toNamed(AppRoutes.addIncome),
              secondLabel: 'Add Expense',
              secondIcon: Icons.remove_rounded,
              onSecond: () => Get.toNamed(AppRoutes.addExpense),
            ),
            const SizedBox(height: 20),
            const AppSectionTitle('Recent Transactions'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: [
                for (final (index, label) in [
                  (0, 'All'),
                  (1, 'Income'),
                  (2, 'Expense'),
                ])
                  ChoiceChip(
                    label: Text(label),
                    selected: filter == index,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => filter = index),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (visible.isEmpty)
              AppEmptyState(
                title: 'No transactions in this view',
                message: entries.isEmpty
                    ? 'Add income or an expense to start tracking cash flow.'
                    : 'Try another filter.',
                actionLabel: entries.isEmpty ? 'Add Income' : null,
                onAction: entries.isEmpty
                    ? () => Get.toNamed(AppRoutes.addIncome)
                    : null,
              ),
            for (final e in visible)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Card(
                  color: theme.colorScheme.surfaceContainerLow,
                  elevation: 0,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _edit(e, income, expense),
                    onLongPress: () => _delete(e, income, expense),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                            child: Icon(
                              e.income
                                  ? Icons.add_rounded
                                  : Icons.remove_rounded,
                              size: 18,
                              color: theme.colorScheme.onSecondaryContainer,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  e.note?.isNotEmpty == true
                                      ? e.note!
                                      : e.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  '${e.title} • ${_accountName(accounts, e.accountId)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(
                                  DateHelper.formatDate(e.date),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AppTrailingAmount(
                              '${e.income ? '+' : '−'}${CurrencyHelper.formatAmount(e.amount)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      }),
    );
  }

  String _accountName(AccountController controller, String? id) {
    if (id == null) return 'Unassigned account';
    final a = controller.accounts.where((x) => x.id == id).firstOrNull;
    return a == null
        ? 'Unassigned account'
        : '${a.institutionName.isEmpty ? '' : '${a.institutionName} '}${a.name}';
  }

  void _edit(_Entry e, IncomeController income, ExpenseController expense) {
    if (e.income) {
      Get.toNamed(
        AppRoutes.addIncome,
        arguments: income.incomes.firstWhere((x) => x.id == e.id),
      );
    } else {
      Get.toNamed(
        AppRoutes.addExpense,
        arguments: expense.expenses.firstWhere((x) => x.id == e.id),
      );
    }
  }

  void _delete(_Entry e, IncomeController income, ExpenseController expense) {
    Get.dialog(
      AlertDialog(
        title: Text('Delete ${e.income ? 'income' : 'expense'}?'),
        content: Text(
          'This ${e.income ? 'income' : 'expense'} entry will be removed.',
        ),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              if (e.income) {
                income.deleteIncome(e.id);
              } else {
                expense.deleteExpense(e.id);
              }
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
}

class _Metric extends StatelessWidget {
  final String label;
  final double amount;
  final IconData icon;
  const _Metric({
    required this.label,
    required this.amount,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyHelper.formatAmount(amount),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Entry {
  final String id;
  final bool income;
  final double amount;
  final DateTime date;
  final String title;
  final String? note;
  final String? accountId;
  const _Entry({
    required this.id,
    required this.income,
    required this.amount,
    required this.date,
    required this.title,
    required this.note,
    required this.accountId,
  });
}
