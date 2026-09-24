import 'package:get/get.dart';

import '../../data/services/financial_calculator.dart';
import '../accounts/account_controller.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';

enum DashboardTransactionTab { all, income, expense, transfer, lendBorrow }

enum DashboardEntryType { income, expense, transfer, lend, borrow }

class DashboardEntry {
  final DashboardEntryType type;
  final Object record;
  final DateTime date;

  const DashboardEntry(this.type, this.record, this.date);
}

class DashboardController extends GetxController {
  final selectedTransactionTab = DashboardTransactionTab.all.obs;
  final monthOnly = false.obs;
  final showAll = false.obs;

  FinancialCalculator? get calculator =>
      Get.find<AccountController>().calculator.value;

  PeriodComparison? currentMonth(DateTime now) {
    final calc = calculator;
    if (calc == null) return null;
    final firstDay = DateTime(now.year, now.month, 1);
    return calc.compare(firstDay.subtract(const Duration(days: 1)), now);
  }

  List<DashboardEntry> entries() {
    final tab = selectedTransactionTab.value;
    final calc = calculator;
    final entries = <DashboardEntry>[];
    if (tab == DashboardTransactionTab.all ||
        tab == DashboardTransactionTab.income) {
      entries.addAll(
        Get.find<IncomeController>().incomes.map(
          (item) =>
              DashboardEntry(DashboardEntryType.income, item, item.incomeDate),
        ),
      );
    }
    if (tab == DashboardTransactionTab.all ||
        tab == DashboardTransactionTab.expense) {
      entries.addAll(
        Get.find<ExpenseController>().expenses.map(
          (item) => DashboardEntry(
            DashboardEntryType.expense,
            item,
            item.expenseDate,
          ),
        ),
      );
    }
    if (calc != null &&
        (tab == DashboardTransactionTab.all ||
            tab == DashboardTransactionTab.transfer)) {
      entries.addAll(
        calc.transfers
            .where((item) => !item.isDeleted)
            .map(
              (item) => DashboardEntry(
                DashboardEntryType.transfer,
                item,
                item.transferDate,
              ),
            ),
      );
    }
    if (tab == DashboardTransactionTab.all ||
        tab == DashboardTransactionTab.lendBorrow) {
      final controller = Get.find<LendBorrowController>();
      entries.addAll(
        controller.lends.map(
          (item) =>
              DashboardEntry(DashboardEntryType.lend, item, item.lendDate),
        ),
      );
      entries.addAll(
        controller.borrows.map(
          (item) =>
              DashboardEntry(DashboardEntryType.borrow, item, item.borrowDate),
        ),
      );
    }
    if (monthOnly.value) {
      final now = DateTime.now();
      entries.removeWhere(
        (item) => item.date.year != now.year || item.date.month != now.month,
      );
    }
    entries.sort((a, b) => b.date.compareTo(a.date));
    return entries;
  }

  void selectTab(DashboardTransactionTab tab, {bool currentMonthOnly = false}) {
    selectedTransactionTab.value = tab;
    monthOnly.value = currentMonthOnly;
    showAll.value = false;
  }
}
