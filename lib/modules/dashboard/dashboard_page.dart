import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import '../category/category_controller.dart';
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
    final categoryController = Get.find<CategoryController>();
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
                lendBorrowController.entries.isEmpty
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
            'Add income, expense, or lend/borrow to get started',
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
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Borrowed',
                  dashboardController.getFormattedBorrowed(),
                ),
                _buildStatItem('Lent', dashboardController.getFormattedLent()),
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
              label: Text('I/E'),
              icon: Icon(Icons.trending_up_rounded),
            ),
            ButtonSegment<DashboardTransactionTab>(
              value: DashboardTransactionTab.lendBorrow,
              label: Text('L/B'),
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
    CategoryController categoryController,
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
          DashboardTransactionTab.all =>
            'No entries yet. Use + to add expense or income.',
          DashboardTransactionTab.incomeExpense =>
            'No income/expense entries yet. Use + to add one.',
          DashboardTransactionTab.lendBorrow =>
            'No lend/borrow entries yet. Use + to add one.',
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
        lendBorrowController.entries.map(
          (entry) => _DashboardEntry.lendBorrow(entry),
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
    CategoryController categoryController,
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

        if (entry.isLendBorrow) {
          final lendBorrow = entry.lendBorrow!;
          final isLend = lendBorrow.type == LendBorrowController.typeLend;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              child: ListTile(
                contentPadding: const EdgeInsets.all(
                  AppConstants.defaultPadding,
                ),
                leading: CircleAvatar(
                  backgroundColor: isLend ? Colors.orange : Colors.blue,
                  child: Icon(
                    isLend
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    color: Colors.white,
                  ),
                ),
                title: Text(lendBorrow.personName),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLend ? 'Lend' : 'Borrow',
                      style: const TextStyle(fontSize: 12),
                    ),
                    if (lendBorrow.note != null && lendBorrow.note!.isNotEmpty)
                      Text(
                        lendBorrow.note!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12),
                      ),
                    Text(
                      DateHelper.formatDate(lendBorrow.transactionDate),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                trailing: Text(
                  CurrencyHelper.formatAmount(lendBorrow.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
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
  final LendBorrow? lendBorrow;

  const _DashboardEntry._({this.income, this.expense, this.lendBorrow});

  factory _DashboardEntry.income(Income income) {
    return _DashboardEntry._(income: income);
  }

  factory _DashboardEntry.expense(Expense expense) {
    return _DashboardEntry._(expense: expense);
  }

  factory _DashboardEntry.lendBorrow(LendBorrow lendBorrow) {
    return _DashboardEntry._(lendBorrow: lendBorrow);
  }

  bool get isIncome => income != null;

  bool get isLendBorrow => lendBorrow != null;

  DateTime get date {
    if (isIncome) {
      return income!.incomeDate;
    }

    if (isLendBorrow) {
      return lendBorrow!.transactionDate;
    }

    return expense!.expenseDate;
  }
}
