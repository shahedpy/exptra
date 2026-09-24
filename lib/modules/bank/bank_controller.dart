import 'package:get/get.dart';

import '../../core/db/app_database.dart';
import '../../data/repositories/bank_repository.dart';

class BankController extends GetxController {
  late final BankRepository repository;
  final banks = <Bank>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    repository = BankRepository(Get.find<AppDatabase>());
    loadBanks();
    super.onInit();
  }

  Future<void> loadBanks() async {
    try {
      isLoading.value = true;
      banks.value = await repository.getAllBanks();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> addBank(String name) async {
    try {
      await repository.insertBank(name: name);
      await loadBanks();
    } catch (error) {
      Get.snackbar('Error', 'Failed to add bank: $error');
    }
  }

  Future<void> updateBank({required String id, required String name}) async {
    try {
      await repository.updateBank(id: id, name: name);
      await loadBanks();
    } catch (error) {
      Get.snackbar('Error', 'Failed to update bank: $error');
    }
  }

  Future<void> deleteBank(Bank bank) async {
    try {
      final accountCount = await repository.getAccountCountByBank(bank.name);
      if (accountCount > 0) {
        Get.snackbar(
          'Cannot Delete',
          'This bank is used by $accountCount account${accountCount == 1 ? '' : 's'}.',
        );
        return;
      }
      await repository.softDelete(bank.id);
      await loadBanks();
      Get.snackbar('Success', 'Bank deleted');
    } catch (error) {
      Get.snackbar('Error', 'Failed to delete bank: $error');
    }
  }

  Future<void> reorderBanks(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= banks.length) return;
    if (newIndex < 0 || newIndex > banks.length) return;

    final updated = List<Bank>.from(banks);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    banks.value = updated;

    try {
      await repository.reorderBanks(updated.map((bank) => bank.id).toList());
    } catch (error) {
      await loadBanks();
      Get.snackbar('Error', 'Failed to reorder banks: $error');
    }
  }
}
