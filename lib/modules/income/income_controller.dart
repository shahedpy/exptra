import 'package:get/get.dart';

import '../../../core/db/app_database.dart';
import '../../../data/repositories/income_repository.dart';

class IncomeController extends GetxController {
  late final IncomeRepository repository;
  final incomes = <Income>[].obs;

  @override
  void onInit() {
    repository = IncomeRepository(Get.find<AppDatabase>());
    loadIncomes();
    super.onInit();
  }

  Future<void> loadIncomes() async {
    incomes.value = await repository.getAllIncomes();
  }

  Future<void> addIncome({
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.insertIncome(amount: amount, note: note, date: date);
      await loadIncomes();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add income: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await repository.softDelete(id);
      await loadIncomes();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete income: $e');
    }
  }

  double getTotalIncome() {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }
}
