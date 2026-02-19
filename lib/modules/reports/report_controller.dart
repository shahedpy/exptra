import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../expense/expense_controller.dart';
import '../income/income_controller.dart';
import '../category/category_controller.dart';
import '../../core/db/app_database.dart';

enum ReportType { monthWise, categoryWise, dailyWise }

enum ReportDataType { expense, income }

class ReportSummaryItem {
  final String label;
  final double amount;
  final int transactionCount;
  final int? color;

  const ReportSummaryItem({
    required this.label,
    required this.amount,
    required this.transactionCount,
    this.color,
  });
}

class ReportController extends GetxController {
  late final ExpenseController expenseController;
  late final IncomeController incomeController;
  late final CategoryController categoryController;

  final selectedDataType = ReportDataType.expense.obs;
  final selectedType = ReportType.monthWise.obs;
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  final expenseMonthWiseReports = <ReportSummaryItem>[].obs;
  final expenseCategoryWiseReports = <ReportSummaryItem>[].obs;
  final expenseDailyWiseReports = <ReportSummaryItem>[].obs;

  final incomeMonthWiseReports = <ReportSummaryItem>[].obs;
  final incomeSourceWiseReports = <ReportSummaryItem>[].obs;
  final incomeDailyWiseReports = <ReportSummaryItem>[].obs;

  final totalAmount = 0.0.obs;
  final totalTransactions = 0.obs;

  @override
  void onInit() {
    expenseController = Get.find<ExpenseController>();
    incomeController = Get.find<IncomeController>();
    categoryController = Get.find<CategoryController>();

    everAll(
      [
        expenseController.expenses,
        incomeController.incomes,
        categoryController.categories,
        selectedMonth,
      ],
      (_) {
        _generateReports();
      },
    );

    _generateReports();
    super.onInit();
  }

  void changeType(ReportType type) {
    selectedType.value = type;
    _refreshSummary();
  }

  void changeDataType(ReportDataType dataType) {
    selectedDataType.value = dataType;
    _refreshSummary();
  }

  void previousMonth() {
    final month = selectedMonth.value;
    selectedMonth.value = DateTime(month.year, month.month - 1);
  }

  void nextMonth() {
    final month = selectedMonth.value;
    selectedMonth.value = DateTime(month.year, month.month + 1);
  }

  bool get canMoveToNextMonth {
    final now = DateTime.now();
    final currentMonth = DateTime(now.year, now.month);
    return selectedMonth.value.isBefore(currentMonth);
  }

  List<ReportSummaryItem> get activeReport {
    if (selectedDataType.value == ReportDataType.expense) {
      switch (selectedType.value) {
        case ReportType.monthWise:
          return expenseMonthWiseReports;
        case ReportType.categoryWise:
          return expenseCategoryWiseReports;
        case ReportType.dailyWise:
          return expenseDailyWiseReports;
      }
    }

    switch (selectedType.value) {
      case ReportType.monthWise:
        return incomeMonthWiseReports;
      case ReportType.categoryWise:
        return incomeSourceWiseReports;
      case ReportType.dailyWise:
        return incomeDailyWiseReports;
    }
  }

  String get reportTitle {
    final prefix = selectedDataType.value == ReportDataType.expense
        ? 'Expense'
        : 'Income';

    switch (selectedType.value) {
      case ReportType.monthWise:
        return '$prefix month wise report';
      case ReportType.categoryWise:
        return selectedDataType.value == ReportDataType.expense
            ? '$prefix category wise report'
            : '$prefix source wise report';
      case ReportType.dailyWise:
        return '$prefix daily report';
    }
  }

  void _generateReports() {
    final expenses = expenseController.expenses;
    final incomes = incomeController.incomes;

    expenseMonthWiseReports.value = _buildExpenseMonthWise(expenses);
    expenseCategoryWiseReports.value = _buildExpenseCategoryWise(expenses);
    expenseDailyWiseReports.value = _buildExpenseDailyWise(expenses);

    incomeMonthWiseReports.value = _buildIncomeMonthWise(incomes);
    incomeSourceWiseReports.value = _buildIncomeSourceWise(incomes);
    incomeDailyWiseReports.value = _buildIncomeDailyWise(incomes);

    _refreshSummary();
  }

  void _refreshSummary() {
    if (selectedDataType.value == ReportDataType.expense) {
      final expenses = expenseController.expenses;
      totalAmount.value = expenses.fold(0.0, (sum, item) => sum + item.amount);
      totalTransactions.value = expenses.length;
      return;
    }

    final incomes = incomeController.incomes;
    totalAmount.value = incomes.fold(0.0, (sum, item) => sum + item.amount);
    totalTransactions.value = incomes.length;
  }

  List<ReportSummaryItem> _buildExpenseMonthWise(List<Expense> expenses) {
    final grouped = <DateTime, List<Expense>>{};

    for (final expense in expenses) {
      final monthKey = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
      );
      grouped.putIfAbsent(monthKey, () => []).add(expense);
    }

    final items = grouped.entries.map((entry) {
      final monthExpenses = entry.value;
      final amount = monthExpenses.fold(0.0, (sum, item) => sum + item.amount);
      return ReportSummaryItem(
        label: _monthLabel(entry.key),
        amount: amount,
        transactionCount: monthExpenses.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseMonthLabel(a.label);
      final second = _parseMonthLabel(b.label);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildExpenseCategoryWise(List<Expense> expenses) {
    final selected = selectedMonth.value;
    final monthExpenses = expenses
        .where(
          (expense) =>
              expense.expenseDate.year == selected.year &&
              expense.expenseDate.month == selected.month,
        )
        .toList();

    final grouped = <String, List<Expense>>{};

    for (final expense in monthExpenses) {
      grouped.putIfAbsent(expense.categoryId, () => []).add(expense);
    }

    final items = grouped.entries.map((entry) {
      final category = categoryController.getCategoryById(entry.key);
      final categoryExpenses = entry.value;
      final amount = categoryExpenses.fold(
        0.0,
        (sum, item) => sum + item.amount,
      );

      return ReportSummaryItem(
        label: category?.name ?? 'Unknown',
        amount: amount,
        transactionCount: categoryExpenses.length,
        color: category?.color,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  List<ReportSummaryItem> _buildExpenseDailyWise(List<Expense> expenses) {
    final selected = selectedMonth.value;
    final monthExpenses = expenses
        .where(
          (expense) =>
              expense.expenseDate.year == selected.year &&
              expense.expenseDate.month == selected.month,
        )
        .toList();

    final grouped = <DateTime, List<Expense>>{};

    for (final expense in monthExpenses) {
      final dayKey = DateTime(
        expense.expenseDate.year,
        expense.expenseDate.month,
        expense.expenseDate.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(expense);
    }

    final items = grouped.entries.map((entry) {
      final dayExpenses = entry.value;
      final amount = dayExpenses.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: _dayLabel(entry.key),
        amount: amount,
        transactionCount: dayExpenses.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseDayLabel(a.label, selected);
      final second = _parseDayLabel(b.label, selected);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildIncomeMonthWise(List<Income> incomes) {
    final grouped = <DateTime, List<Income>>{};

    for (final income in incomes) {
      final monthKey = DateTime(
        income.incomeDate.year,
        income.incomeDate.month,
      );
      grouped.putIfAbsent(monthKey, () => []).add(income);
    }

    final items = grouped.entries.map((entry) {
      final monthIncomes = entry.value;
      final amount = monthIncomes.fold(0.0, (sum, item) => sum + item.amount);
      return ReportSummaryItem(
        label: _monthLabel(entry.key),
        amount: amount,
        transactionCount: monthIncomes.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseMonthLabel(a.label);
      final second = _parseMonthLabel(b.label);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildIncomeSourceWise(List<Income> incomes) {
    final selected = selectedMonth.value;
    final monthIncomes = incomes
        .where(
          (income) =>
              income.incomeDate.year == selected.year &&
              income.incomeDate.month == selected.month,
        )
        .toList();

    final grouped = <String, List<Income>>{};

    for (final income in monthIncomes) {
      final source = (income.source ?? '').trim();
      final key = source.isEmpty ? 'Unknown Source' : source;
      grouped.putIfAbsent(key, () => []).add(income);
    }

    final items = grouped.entries.map((entry) {
      final sourceIncomes = entry.value;
      final amount = sourceIncomes.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: entry.key,
        amount: amount,
        transactionCount: sourceIncomes.length,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  List<ReportSummaryItem> _buildIncomeDailyWise(List<Income> incomes) {
    final selected = selectedMonth.value;
    final monthIncomes = incomes
        .where(
          (income) =>
              income.incomeDate.year == selected.year &&
              income.incomeDate.month == selected.month,
        )
        .toList();

    final grouped = <DateTime, List<Income>>{};

    for (final income in monthIncomes) {
      final dayKey = DateTime(
        income.incomeDate.year,
        income.incomeDate.month,
        income.incomeDate.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(income);
    }

    final items = grouped.entries.map((entry) {
      final dayIncomes = entry.value;
      final amount = dayIncomes.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: _dayLabel(entry.key),
        amount: amount,
        transactionCount: dayIncomes.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseDayLabel(a.label, selected);
      final second = _parseDayLabel(b.label, selected);
      return second.compareTo(first);
    });

    return items;
  }

  String _monthLabel(DateTime date) {
    const names = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${names[date.month - 1]} ${date.year}';
  }

  DateTime _parseMonthLabel(String label) {
    final parts = label.split(' ');
    if (parts.length != 2) {
      return DateTime(1970);
    }

    const monthIndex = {
      'Jan': 1,
      'Feb': 2,
      'Mar': 3,
      'Apr': 4,
      'May': 5,
      'Jun': 6,
      'Jul': 7,
      'Aug': 8,
      'Sep': 9,
      'Oct': 10,
      'Nov': 11,
      'Dec': 12,
    };

    final month = monthIndex[parts[0]] ?? 1;
    final year = int.tryParse(parts[1]) ?? 1970;
    return DateTime(year, month);
  }

  String _dayLabel(DateTime date) {
    return date.day.toString().padLeft(2, '0');
  }

  DateTime _parseDayLabel(String label, DateTime month) {
    final day = int.tryParse(label) ?? 1;
    return DateTime(month.year, month.month, day);
  }

  Color colorForItem(ReportSummaryItem item, ThemeData theme) {
    if (item.color == null) {
      return theme.colorScheme.primary;
    }
    return Color(item.color!);
  }
}
