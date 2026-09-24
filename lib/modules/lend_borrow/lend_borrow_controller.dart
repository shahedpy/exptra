import 'package:get/get.dart';
import '../accounts/account_controller.dart';
import '../../data/repositories/accounting_repository.dart';
import '../../data/services/financial_calculator.dart';

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
  late final AccountingRepository accountingRepository;
  final outstandingLends = <String, int>{}.obs;
  final outstandingBorrows = <String, int>{}.obs;

  @override
  void onInit() {
    final db = Get.find<AppDatabase>();
    accountingRepository = AccountingRepository(db);
    lendRepository = LendRepository(db);
    borrowRepository = BorrowRepository(db);
    loadEntries();
    super.onInit();
  }

  Future<void> loadEntries() async {
    lends.value = await lendRepository.getAllLends();
    borrows.value = await borrowRepository.getAllBorrows();
    final calculator = await accountingRepository.calculator();
    outstandingLends.value = {
      for (final row in lends) row.id: calculator.outstandingLend(row),
    };
    outstandingBorrows.value = {
      for (final row in borrows) row.id: calculator.outstandingBorrow(row),
    };
    if (Get.isRegistered<AccountController>()) {
      await Get.find<AccountController>().reload();
    }
  }

  Future<void> addEntry({
    required String personName,
    required double amount,
    String? accountId,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    try {
      if (type == typeLend) {
        await lendRepository.insertLend(
          personName: personName,
          amount: amount,
          accountId: accountId,
          note: note,
          date: date,
        );
      } else if (type == typeBorrow) {
        await borrowRepository.insertBorrow(
          personName: personName,
          amount: amount,
          accountId: accountId,
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

  Future<void> updateEntry({
    required String id,
    required String personName,
    required double amount,
    String? accountId,
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
          accountId: accountId,
          note: note,
          date: date,
        );
      } else if (type == typeBorrow) {
        await borrowRepository.updateBorrow(
          id: id,
          personName: personName,
          amount: amount,
          accountId: accountId,
          note: note,
          date: date,
        );
      }
      await loadEntries();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update entry: $e');
    }
  }

  Future<void> repay({
    required String id,
    required String type,
    required String accountId,
    required double amount,
    required DateTime date,
  }) async {
    if (type == typeLend) {
      await accountingRepository.repayLend(
        lendId: id,
        accountId: accountId,
        amount: amount,
        date: date,
      );
    } else {
      await accountingRepository.repayBorrow(
        borrowId: id,
        accountId: accountId,
        amount: amount,
        date: date,
      );
    }
    await loadEntries();
  }

  double getTotalLent() =>
      Money.bdt(outstandingLends.values.fold<int>(0, (s, v) => s + v));
  double getTotalBorrowed() =>
      Money.bdt(outstandingBorrows.values.fold<int>(0, (s, v) => s + v));
}
