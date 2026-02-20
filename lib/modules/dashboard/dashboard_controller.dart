import 'package:get/get.dart';
import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import '../../core/utils/helpers.dart';

enum DashboardTransactionTab { all, incomeExpense, lendBorrow }

class DashboardController extends GetxController {
  late final ExpenseController expenseController;
  late final IncomeController incomeController;
  late final LendBorrowController lendBorrowController;
  final selectedTransactionTab = DashboardTransactionTab.all.obs;

  @override
  void onInit() {
    expenseController = Get.find<ExpenseController>();
    incomeController = Get.find<IncomeController>();
    lendBorrowController = Get.find<LendBorrowController>();
    super.onInit();
  }

  double getTotalExpenses() {
    return expenseController.getTotalExpenses();
  }

  double getTotalIncome() {
    return incomeController.getTotalIncome();
  }

  double getBalance() {
    return getTotalIncome() +
        getTotalBorrowed() -
        getTotalExpenses() -
        getTotalLent();
  }

  double getTotalLent() {
    return lendBorrowController.getTotalLent();
  }

  double getTotalBorrowed() {
    return lendBorrowController.getTotalBorrowed();
  }

  String getFormattedIncome() {
    return CurrencyHelper.formatAmount(getTotalIncome());
  }

  String getFormattedExpense() {
    return CurrencyHelper.formatAmount(getTotalExpenses());
  }

  String getFormattedBalance() {
    return CurrencyHelper.formatAmount(getBalance());
  }

  String getFormattedLent() {
    return CurrencyHelper.formatAmount(getTotalLent());
  }

  String getFormattedBorrowed() {
    return CurrencyHelper.formatAmount(getTotalBorrowed());
  }

  int getExpenseCount() {
    return expenseController.expenses.length;
  }

  void changeTransactionTab(DashboardTransactionTab tab) {
    selectedTransactionTab.value = tab;
  }
}
