import 'package:get/get.dart';
import '../../../data/repositories/expense_repository.dart';
import '../../../core/db/app_database.dart';

class ExpenseController extends GetxController {
  late final ExpenseRepository repository;
  final expenses = <Expense>[].obs;

  @override
  void onInit() {
    repository = ExpenseRepository(Get.find<AppDatabase>());
    loadExpenses();
    super.onInit();
  }

  Future<void> loadExpenses() async {
    expenses.value = await repository.getAllExpenses();
  }

  Future<void> addExpense({
    required String categoryId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.insertExpense(
        categoryId: categoryId,
        amount: amount,
        note: note,
        date: date,
      );
      await loadExpenses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add expense: $e');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await repository.softDelete(id);
      await loadExpenses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete expense: $e');
    }
  }

  Future<void> updateExpense({
    required String id,
    required String categoryId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.updateExpense(
        id: id,
        categoryId: categoryId,
        amount: amount,
        note: note,
        date: date,
      );
      await loadExpenses();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update expense: $e');
    }
  }

  double getTotalExpenses() {
    return expenses.fold(0.0, (sum, expense) => sum + expense.amount);
  }
}
