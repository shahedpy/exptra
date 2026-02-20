import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../expense_category/expense_category_controller.dart';
import '../income_source/income_source_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import '../../core/db/app_database.dart';

enum ReportType { monthWise, categoryWise, dailyWise }

enum ReportDataType { expense, income, lend, borrow }

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
  late final ExpenseCategoryController categoryController;
  late final IncomeSourceController incomeSourceController;
  late final LendBorrowController lendBorrowController;

  final selectedDataType = ReportDataType.income.obs;
  final selectedType = ReportType.monthWise.obs;
  final selectedMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;

  final expenseMonthWiseReports = <ReportSummaryItem>[].obs;
  final expenseCategoryWiseReports = <ReportSummaryItem>[].obs;
  final expenseDailyWiseReports = <ReportSummaryItem>[].obs;

  final incomeMonthWiseReports = <ReportSummaryItem>[].obs;
  final incomeSourceWiseReports = <ReportSummaryItem>[].obs;
  final incomeDailyWiseReports = <ReportSummaryItem>[].obs;

  final lendMonthWiseReports = <ReportSummaryItem>[].obs;
  final lendPersonWiseReports = <ReportSummaryItem>[].obs;
  final lendDailyWiseReports = <ReportSummaryItem>[].obs;

  final borrowMonthWiseReports = <ReportSummaryItem>[].obs;
  final borrowPersonWiseReports = <ReportSummaryItem>[].obs;
  final borrowDailyWiseReports = <ReportSummaryItem>[].obs;

  final totalAmount = 0.0.obs;
  final totalTransactions = 0.obs;

  @override
  void onInit() {
    expenseController = Get.find<ExpenseController>();
    incomeController = Get.find<IncomeController>();
    categoryController = Get.find<ExpenseCategoryController>();
    incomeSourceController = Get.find<IncomeSourceController>();
    lendBorrowController = Get.find<LendBorrowController>();

    everAll(
      [
        expenseController.expenses,
        incomeController.incomes,
        categoryController.categories,
        incomeSourceController.incomeSources,
        lendBorrowController.lends,
        lendBorrowController.borrows,
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
    switch (selectedType.value) {
      case ReportType.monthWise:
        return switch (selectedDataType.value) {
          ReportDataType.expense => expenseMonthWiseReports,
          ReportDataType.income => incomeMonthWiseReports,
          ReportDataType.lend => lendMonthWiseReports,
          ReportDataType.borrow => borrowMonthWiseReports,
        };
      case ReportType.categoryWise:
        return switch (selectedDataType.value) {
          ReportDataType.expense => expenseCategoryWiseReports,
          ReportDataType.income => incomeSourceWiseReports,
          ReportDataType.lend => lendPersonWiseReports,
          ReportDataType.borrow => borrowPersonWiseReports,
        };
      case ReportType.dailyWise:
        return switch (selectedDataType.value) {
          ReportDataType.expense => expenseDailyWiseReports,
          ReportDataType.income => incomeDailyWiseReports,
          ReportDataType.lend => lendDailyWiseReports,
          ReportDataType.borrow => borrowDailyWiseReports,
        };
    }
  }

  String get reportTitle {
    final prefix = switch (selectedDataType.value) {
      ReportDataType.expense => 'Expense',
      ReportDataType.income => 'Income',
      ReportDataType.lend => 'Lend',
      ReportDataType.borrow => 'Borrow',
    };

    switch (selectedType.value) {
      case ReportType.monthWise:
        return '$prefix month wise report';
      case ReportType.categoryWise:
        if (selectedDataType.value == ReportDataType.expense) {
          return '$prefix category wise report';
        }
        if (selectedDataType.value == ReportDataType.income) {
          return '$prefix source wise report';
        }
        return '$prefix person wise report';
      case ReportType.dailyWise:
        return '$prefix daily report';
    }
  }

  void _generateReports() {
    final expenses = expenseController.expenses;
    final incomes = incomeController.incomes;
    final lends = lendBorrowController.lends;
    final borrows = lendBorrowController.borrows;

    expenseMonthWiseReports.value = _buildExpenseMonthWise(expenses);
    expenseCategoryWiseReports.value = _buildExpenseCategoryWise(expenses);
    expenseDailyWiseReports.value = _buildExpenseDailyWise(expenses);

    incomeMonthWiseReports.value = _buildIncomeMonthWise(incomes);
    incomeSourceWiseReports.value = _buildIncomeSourceWise(incomes);
    incomeDailyWiseReports.value = _buildIncomeDailyWise(incomes);

    lendMonthWiseReports.value = _buildLendMonthWise(lends);
    lendPersonWiseReports.value = _buildLendPersonWise(lends);
    lendDailyWiseReports.value = _buildLendDailyWise(lends);

    borrowMonthWiseReports.value = _buildBorrowMonthWise(borrows);
    borrowPersonWiseReports.value = _buildBorrowPersonWise(borrows);
    borrowDailyWiseReports.value = _buildBorrowDailyWise(borrows);

    _refreshSummary();
  }

  void _refreshSummary() {
    switch (selectedDataType.value) {
      case ReportDataType.expense:
        final expenses = expenseController.expenses;
        totalAmount.value = expenses.fold(
          0.0,
          (sum, item) => sum + item.amount,
        );
        totalTransactions.value = expenses.length;
        return;
      case ReportDataType.income:
        final incomes = incomeController.incomes;
        totalAmount.value = incomes.fold(0.0, (sum, item) => sum + item.amount);
        totalTransactions.value = incomes.length;
        return;
      case ReportDataType.lend:
        final lends = lendBorrowController.lends;
        totalAmount.value = lends.fold(0.0, (sum, item) => sum + item.amount);
        totalTransactions.value = lends.length;
        return;
      case ReportDataType.borrow:
        final borrows = lendBorrowController.borrows;
        totalAmount.value = borrows.fold(0.0, (sum, item) => sum + item.amount);
        totalTransactions.value = borrows.length;
        return;
    }
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
      final sourceName = incomeSourceController
          .getIncomeSourceById(income.sourceId ?? '')
          ?.name;
      final legacySource = (income.source ?? '').trim();
      final key = (sourceName != null && sourceName.isNotEmpty)
          ? sourceName
          : (legacySource.isEmpty ? 'Unknown Source' : legacySource);
      grouped.putIfAbsent(key, () => []).add(income);
    }

    final items = grouped.entries.map((entry) {
      final sourceIncomes = entry.value;
      final amount = sourceIncomes.fold(0.0, (sum, item) => sum + item.amount);
      final sourceId = sourceIncomes.first.sourceId;
      final sourceColor = sourceId == null
          ? null
          : incomeSourceController.getIncomeSourceById(sourceId)?.color;

      return ReportSummaryItem(
        label: entry.key,
        amount: amount,
        transactionCount: sourceIncomes.length,
        color: sourceColor,
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

  List<ReportSummaryItem> _buildLendMonthWise(List<Lend> lends) {
    final grouped = <DateTime, List<Lend>>{};

    for (final lend in lends) {
      final monthKey = DateTime(lend.lendDate.year, lend.lendDate.month);
      grouped.putIfAbsent(monthKey, () => []).add(lend);
    }

    final items = grouped.entries.map((entry) {
      final monthLends = entry.value;
      final amount = monthLends.fold(0.0, (sum, item) => sum + item.amount);
      return ReportSummaryItem(
        label: _monthLabel(entry.key),
        amount: amount,
        transactionCount: monthLends.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseMonthLabel(a.label);
      final second = _parseMonthLabel(b.label);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildLendPersonWise(List<Lend> lends) {
    final selected = selectedMonth.value;
    final monthLends = lends
        .where(
          (lend) =>
              lend.lendDate.year == selected.year &&
              lend.lendDate.month == selected.month,
        )
        .toList();

    final grouped = <String, List<Lend>>{};

    for (final lend in monthLends) {
      grouped.putIfAbsent(lend.personName, () => []).add(lend);
    }

    final items = grouped.entries.map((entry) {
      final personLends = entry.value;
      final amount = personLends.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: entry.key,
        amount: amount,
        transactionCount: personLends.length,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  List<ReportSummaryItem> _buildLendDailyWise(List<Lend> lends) {
    final selected = selectedMonth.value;
    final monthLends = lends
        .where(
          (lend) =>
              lend.lendDate.year == selected.year &&
              lend.lendDate.month == selected.month,
        )
        .toList();

    final grouped = <DateTime, List<Lend>>{};

    for (final lend in monthLends) {
      final dayKey = DateTime(
        lend.lendDate.year,
        lend.lendDate.month,
        lend.lendDate.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(lend);
    }

    final items = grouped.entries.map((entry) {
      final dayLends = entry.value;
      final amount = dayLends.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: _dayLabel(entry.key),
        amount: amount,
        transactionCount: dayLends.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseDayLabel(a.label, selected);
      final second = _parseDayLabel(b.label, selected);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildBorrowMonthWise(List<Borrow> borrows) {
    final grouped = <DateTime, List<Borrow>>{};

    for (final borrow in borrows) {
      final monthKey = DateTime(
        borrow.borrowDate.year,
        borrow.borrowDate.month,
      );
      grouped.putIfAbsent(monthKey, () => []).add(borrow);
    }

    final items = grouped.entries.map((entry) {
      final monthBorrows = entry.value;
      final amount = monthBorrows.fold(0.0, (sum, item) => sum + item.amount);
      return ReportSummaryItem(
        label: _monthLabel(entry.key),
        amount: amount,
        transactionCount: monthBorrows.length,
      );
    }).toList();

    items.sort((a, b) {
      final first = _parseMonthLabel(a.label);
      final second = _parseMonthLabel(b.label);
      return second.compareTo(first);
    });

    return items;
  }

  List<ReportSummaryItem> _buildBorrowPersonWise(List<Borrow> borrows) {
    final selected = selectedMonth.value;
    final monthBorrows = borrows
        .where(
          (borrow) =>
              borrow.borrowDate.year == selected.year &&
              borrow.borrowDate.month == selected.month,
        )
        .toList();

    final grouped = <String, List<Borrow>>{};

    for (final borrow in monthBorrows) {
      grouped.putIfAbsent(borrow.personName, () => []).add(borrow);
    }

    final items = grouped.entries.map((entry) {
      final personBorrows = entry.value;
      final amount = personBorrows.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: entry.key,
        amount: amount,
        transactionCount: personBorrows.length,
      );
    }).toList();

    items.sort((a, b) => b.amount.compareTo(a.amount));
    return items;
  }

  List<ReportSummaryItem> _buildBorrowDailyWise(List<Borrow> borrows) {
    final selected = selectedMonth.value;
    final monthBorrows = borrows
        .where(
          (borrow) =>
              borrow.borrowDate.year == selected.year &&
              borrow.borrowDate.month == selected.month,
        )
        .toList();

    final grouped = <DateTime, List<Borrow>>{};

    for (final borrow in monthBorrows) {
      final dayKey = DateTime(
        borrow.borrowDate.year,
        borrow.borrowDate.month,
        borrow.borrowDate.day,
      );
      grouped.putIfAbsent(dayKey, () => []).add(borrow);
    }

    final items = grouped.entries.map((entry) {
      final dayBorrows = entry.value;
      final amount = dayBorrows.fold(0.0, (sum, item) => sum + item.amount);

      return ReportSummaryItem(
        label: _dayLabel(entry.key),
        amount: amount,
        transactionCount: dayBorrows.length,
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
