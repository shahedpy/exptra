import 'package:get/get.dart';
import '../expense/expense_controller.dart';
import '../../core/utils/helpers.dart';

class DashboardController extends GetxController {
  late final ExpenseController expenseController;

  @override
  void onInit() {
    expenseController = Get.find<ExpenseController>();
    super.onInit();
  }

  double getTotalExpenses() {
    return expenseController.getTotalExpenses();
  }

  String getFormattedTotal() {
    return CurrencyHelper.formatAmount(getTotalExpenses());
  }

  int getExpenseCount() {
    return expenseController.expenses.length;
  }

  String getAverageExpense() {
    if (expenseController.expenses.isEmpty) {
      return CurrencyHelper.formatAmount(0);
    }
    final average = getTotalExpenses() / expenseController.expenses.length;
    return CurrencyHelper.formatAmount(average);
  }
}

