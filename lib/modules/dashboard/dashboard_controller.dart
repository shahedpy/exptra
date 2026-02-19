import 'package:get/get.dart';
import '../expense/expense_controller.dart';
import '../income/income_controller.dart';
import '../../core/utils/helpers.dart';

enum DashboardTransactionTab { all, income, expense }

class DashboardController extends GetxController {
  late final ExpenseController expenseController;
  late final IncomeController incomeController;
  final selectedTransactionTab = DashboardTransactionTab.all.obs;

  @override
  void onInit() {
    expenseController = Get.find<ExpenseController>();
    incomeController = Get.find<IncomeController>();
    super.onInit();
  }

  double getTotalExpenses() {
    return expenseController.getTotalExpenses();
  }

  double getTotalIncome() {
    return incomeController.getTotalIncome();
  }

  double getBalance() {
    return getTotalIncome() - getTotalExpenses();
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

  int getExpenseCount() {
    return expenseController.expenses.length;
  }

  void changeTransactionTab(DashboardTransactionTab tab) {
    selectedTransactionTab.value = tab;
  }
}
