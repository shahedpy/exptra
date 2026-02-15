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
}
