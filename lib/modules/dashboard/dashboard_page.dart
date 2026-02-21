import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import '../expense_category/expense_category_controller.dart';
import '../income_source/income_source_controller.dart';
import 'dashboard_controller.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_constants.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final expenseController = Get.find<ExpenseController>();
    final incomeController = Get.find<IncomeController>();
    final lendBorrowController = Get.find<LendBorrowController>();
    final categoryController = Get.find<ExpenseCategoryController>();
    final incomeSourceController = Get.find<IncomeSourceController>();
    final dashboardController = Get.put(DashboardController());

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Exptra',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Obx(
        () =>
            expenseController.expenses.isEmpty &&
                incomeController.incomes.isEmpty &&
                lendBorrowController.lends.isEmpty &&
                lendBorrowController.borrows.isEmpty
            ? _buildEmptyState()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildSummaryCard(dashboardController),
                    const SizedBox(height: AppConstants.defaultPadding),
                    _buildTransactionTypeSelector(dashboardController),
                    const SizedBox(height: 8),
                    _buildTransactionsSection(
                      expenseController,
                      incomeController,
                      lendBorrowController,
                      categoryController,
                      incomeSourceController,
                      dashboardController,
                    ),
                  ],
                ),
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
            'No entries yet',
            style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 8),
          Text(
            'Add income, expense, lend, or borrow to get started',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem(
                      'Income',
                      dashboardController.getFormattedIncome(),
                    ),
                    _buildStatItem(
                      'Borrowed',
                      dashboardController.getFormattedBorrowed(),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatItem(
                      'Expense',
                      dashboardController.getFormattedExpense(),
                    ),
                    _buildStatItem(
                      'Lent',
                      dashboardController.getFormattedLent(),
                    ),
                  ],
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
      crossAxisAlignment: CrossAxisAlignment.start,
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

  Widget _buildTransactionTypeSelector(
    DashboardController dashboardController,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      child: Obx(
        () => SegmentedButton<DashboardTransactionTab>(
          segments: const [
            ButtonSegment<DashboardTransactionTab>(
              value: DashboardTransactionTab.all,
              label: Text('All'),
              icon: Icon(Icons.list_rounded),
            ),
            ButtonSegment<DashboardTransactionTab>(
              value: DashboardTransactionTab.incomeExpense,
              label: Text('Inc/Exp'),
              icon: Icon(Icons.swap_vert_rounded),
            ),
            ButtonSegment<DashboardTransactionTab>(
              value: DashboardTransactionTab.lendBorrow,
              label: Text('Len/Bor'),
              icon: Icon(Icons.sync_alt_rounded),
            ),
          ],
          selected: {dashboardController.selectedTransactionTab.value},
          onSelectionChanged: (tabs) {
            if (tabs.isNotEmpty) {
              dashboardController.changeTransactionTab(tabs.first);
            }
          },
          showSelectedIcon: false,
        ),
      ),
    );
  }

  Widget _buildTransactionsSection(
    ExpenseController expenseController,
    IncomeController incomeController,
    LendBorrowController lendBorrowController,
    ExpenseCategoryController categoryController,
    IncomeSourceController incomeSourceController,
    DashboardController dashboardController,
  ) {
    return Obx(() {
      final selectedTab = dashboardController.selectedTransactionTab.value;
      final entries = _getFilteredEntries(
        expenseController,
        incomeController,
        lendBorrowController,
        selectedTab,
      );

      if (entries.isEmpty) {
        final message = switch (selectedTab) {
          DashboardTransactionTab.all => 'No entries yet.',
          DashboardTransactionTab.incomeExpense =>
            'No income/expense entries yet.',
          DashboardTransactionTab.lendBorrow => 'No lend/borrow entries yet.',
        };

        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppConstants.defaultPadding,
          ),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(AppConstants.defaultPadding),
              child: Text(
                message,
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ),
          ),
        );
      }

      return _buildTransactionsList(
        entries,
        expenseController,
        incomeController,
        lendBorrowController,
        categoryController,
        incomeSourceController,
      );
    });
  }

  List<_DashboardEntry> _getFilteredEntries(
    ExpenseController expenseController,
    IncomeController incomeController,
    LendBorrowController lendBorrowController,
    DashboardTransactionTab selectedTab,
  ) {
    final entries = <_DashboardEntry>[];

    if (selectedTab == DashboardTransactionTab.all ||
        selectedTab == DashboardTransactionTab.incomeExpense) {
      entries.addAll(
        incomeController.incomes.map(
          (income) => _DashboardEntry.income(income),
        ),
      );
    }

    if (selectedTab == DashboardTransactionTab.all ||
        selectedTab == DashboardTransactionTab.incomeExpense) {
      entries.addAll(
        expenseController.expenses.map(
          (expense) => _DashboardEntry.expense(expense),
        ),
      );
    }

    if (selectedTab == DashboardTransactionTab.all ||
        selectedTab == DashboardTransactionTab.lendBorrow) {
      entries.addAll(
        lendBorrowController.lends.map((entry) => _DashboardEntry.lend(entry)),
      );
      entries.addAll(
        lendBorrowController.borrows.map(
          (entry) => _DashboardEntry.borrow(entry),
        ),
      );
    }

    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  Widget _buildTransactionsList(
    List<_DashboardEntry> entries,
    ExpenseController expenseController,
    IncomeController incomeController,
    LendBorrowController lendBorrowController,
    ExpenseCategoryController categoryController,
    IncomeSourceController incomeSourceController,
  ) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      itemCount: entries.length,
      itemBuilder: (_, index) {
        final entry = entries[index];

        if (entry.isIncome) {
          final income = entry.income!;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),

            child: ListTile(
              contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.add_card, color: Colors.white),
              ),
              title: Text(
                incomeSourceController
                        .getIncomeSourceById(income.sourceId ?? '')
                        ?.name ??
                    (income.source != null && income.source!.isNotEmpty
                        ? income.source!
                        : 'Income'),
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
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
          );
        }

        if (entry.isLend || entry.isBorrow) {
          final isLend = entry.isLend;
          final personName = isLend
              ? entry.lend!.personName
              : entry.borrow!.personName;
          final amount = isLend ? entry.lend!.amount : entry.borrow!.amount;
          final note = isLend ? entry.lend!.note : entry.borrow!.note;
          final date = isLend ? entry.lend!.lendDate : entry.borrow!.borrowDate;
          final settled = isLend
              ? entry.lend!.isSettled
              : entry.borrow!.isSettled;
          final settledLabel = isLend ? 'Paid' : 'Returned';
          final avatarColor = settled
              ? Colors.grey.shade400
              : (isLend ? Colors.orange : Colors.blue);

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
              leading: CircleAvatar(
                backgroundColor: avatarColor,
                child: Icon(
                  isLend
                      ? Icons.call_made_rounded
                      : Icons.call_received_rounded,
                  color: Colors.white,
                ),
              ),
              title: Text(
                personName,
                style: TextStyle(
                  decoration: settled
                      ? TextDecoration.lineThrough
                      : TextDecoration.none,
                  color: settled ? Colors.grey : null,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLend ? 'Lend' : 'Borrow',
                    style: TextStyle(
                      fontSize: 12,
                      color: settled ? Colors.grey : null,
                    ),
                  ),
                  if (note != null && note.isNotEmpty)
                    Text(
                      note,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                  Text(
                    DateHelper.formatDate(date),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatAmount(amount),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: settled ? Colors.grey : null,
                      decoration: settled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // show settled/paid status without allowing toggling
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: settled
                          ? Colors.green.shade100
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: settled
                            ? Colors.green.shade400
                            : Colors.grey.shade400,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          settled
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_unchecked_rounded,
                          size: 12,
                          color: settled
                              ? Colors.green.shade700
                              : Colors.grey.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          settledLabel,
                          style: TextStyle(
                            fontSize: 11,
                            color: settled
                                ? Colors.green.shade700
                                : Colors.grey.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final expense = entry.expense!;
        final category = categoryController.getCategoryById(expense.categoryId);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
            leading: CircleAvatar(
              backgroundColor: ColorHelper.getColorFromInt(category?.color),
              child: const Icon(Icons.category, color: Colors.white),
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
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
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
        );
      },
    );
  }
}

class _DashboardEntry {
  final Income? income;
  final Expense? expense;
  final Lend? lend;
  final Borrow? borrow;

  const _DashboardEntry._({this.income, this.expense, this.lend, this.borrow});

  factory _DashboardEntry.income(Income income) {
    return _DashboardEntry._(income: income);
  }

  factory _DashboardEntry.expense(Expense expense) {
    return _DashboardEntry._(expense: expense);
  }

  factory _DashboardEntry.lend(Lend lend) {
    return _DashboardEntry._(lend: lend);
  }

  factory _DashboardEntry.borrow(Borrow borrow) {
    return _DashboardEntry._(borrow: borrow);
  }

  bool get isIncome => income != null;

  bool get isLend => lend != null;

  bool get isBorrow => borrow != null;

  DateTime get date {
    if (isIncome) {
      return income!.incomeDate;
    }

    if (isLend) {
      return lend!.lendDate;
    }

    if (isBorrow) {
      return borrow!.borrowDate;
    }

    return expense!.expenseDate;
  }
}
