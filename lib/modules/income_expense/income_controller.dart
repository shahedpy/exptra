import 'package:get/get.dart';
import '../accounts/account_controller.dart';

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
    String? accountId,
    String? sourceId,
    String? source,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.insertIncome(
        amount: amount,
        accountId: accountId,
        sourceId: sourceId,
        source: source,
        note: note,
        date: date,
      );
      await loadIncomes();
      if (Get.isRegistered<AccountController>()) {
        await Get.find<AccountController>().reload();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to add income: $e');
    }
  }

  Future<void> deleteIncome(String id) async {
    try {
      await repository.softDelete(id);
      await loadIncomes();
      if (Get.isRegistered<AccountController>()) {
        await Get.find<AccountController>().reload();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete income: $e');
    }
  }

  Future<void> updateIncome({
    required String id,
    required double amount,
    String? accountId,
    String? sourceId,
    String? source,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.updateIncome(
        id: id,
        amount: amount,
        accountId: accountId,
        sourceId: sourceId,
        source: source,
        note: note,
        date: date,
      );
      await loadIncomes();
      if (Get.isRegistered<AccountController>()) {
        await Get.find<AccountController>().reload();
      }
    } catch (e) {
      Get.snackbar('Error', 'Failed to update income: $e');
    }
  }

  double getTotalIncome() {
    return incomes.fold(0.0, (sum, income) => sum + income.amount);
  }
}
