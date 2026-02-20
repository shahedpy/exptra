import 'package:get/get.dart';

import '../../core/db/app_database.dart';
import '../../data/repositories/lend_repository.dart';
import '../../data/repositories/borrow_repository.dart';

class LendBorrowController extends GetxController {
  static const String typeLend = 'lend';
  static const String typeBorrow = 'borrow';

  late final LendRepository lendRepository;
  late final BorrowRepository borrowRepository;
  final lends = <Lend>[].obs;
  final borrows = <Borrow>[].obs;

  @override
  void onInit() {
    final db = Get.find<AppDatabase>();
    lendRepository = LendRepository(db);
    borrowRepository = BorrowRepository(db);
    loadEntries();
    super.onInit();
  }

  Future<void> loadEntries() async {
    lends.value = await lendRepository.getAllLends();
    borrows.value = await borrowRepository.getAllBorrows();
  }

  Future<void> addEntry({
    required String personName,
    required double amount,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    try {
      if (type == typeLend) {
        await lendRepository.insertLend(
          personName: personName,
          amount: amount,
          note: note,
          date: date,
        );
      } else if (type == typeBorrow) {
        await borrowRepository.insertBorrow(
          personName: personName,
          amount: amount,
          note: note,
          date: date,
        );
      }
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add entry: $e');
    }
  }

  Future<void> deleteEntry(String id, String type) async {
    try {
      if (type == typeLend) {
        await lendRepository.softDelete(id);
      } else if (type == typeBorrow) {
        await borrowRepository.softDelete(id);
      }
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete entry: $e');
    }
  }

  Future<void> toggleSettled(String id, bool currentValue, String type) async {
    try {
      if (type == typeLend) {
        await lendRepository.toggleSettled(id, !currentValue);
      } else if (type == typeBorrow) {
        await borrowRepository.toggleSettled(id, !currentValue);
      }
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update entry: $e');
    }
  }

  Future<void> updateEntry({
    required String id,
    required String personName,
    required double amount,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    try {
      if (type == typeLend) {
        await lendRepository.updateLend(
          id: id,
          personName: personName,
          amount: amount,
          note: note,
          date: date,
        );
      } else if (type == typeBorrow) {
        await borrowRepository.updateBorrow(
          id: id,
          personName: personName,
          amount: amount,
          note: note,
          date: date,
        );
      }
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update entry: $e');
    }
  }

  double getTotalLent() {
    return lends
        .where((entry) => !entry.isSettled)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double getTotalBorrowed() {
    return borrows
        .where((entry) => !entry.isSettled)
        .fold(0.0, (sum, entry) => sum + entry.amount);
  }
}
