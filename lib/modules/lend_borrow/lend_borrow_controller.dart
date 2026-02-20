import 'package:get/get.dart';

import '../../core/db/app_database.dart';
import '../../data/repositories/lend_borrow_repository.dart';

class LendBorrowController extends GetxController {
  static const String typeLend = 'lend';
  static const String typeBorrow = 'borrow';

  late final LendBorrowRepository repository;
  final entries = <LendBorrow>[].obs;

  @override
  void onInit() {
    repository = LendBorrowRepository(Get.find<AppDatabase>());
    loadEntries();
    super.onInit();
  }

  Future<void> loadEntries() async {
    entries.value = await repository.getAllEntries();
  }

  Future<void> addEntry({
    required String personName,
    required double amount,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    try {
      await repository.insertLendBorrow(
        personName: personName,
        amount: amount,
        type: type,
        note: note,
        date: date,
      );
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add entry: $e');
    }
  }

  Future<void> deleteEntry(String id) async {
    try {
      await repository.softDelete(id);
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete entry: $e');
    }
  }

  Future<void> toggleSettled(String id, bool currentValue) async {
    try {
      await repository.toggleSettled(id, !currentValue);
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update entry: $e');
    }
  }

  double getTotalLent() {
    return entries
        .where((entry) => entry.type == typeLend)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double getTotalBorrowed() {
    return entries
        .where((entry) => entry.type == typeBorrow)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }
}
