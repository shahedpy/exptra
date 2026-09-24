import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../data/repositories/accounting_repository.dart';
import '../../data/services/financial_calculator.dart';

class AccountController extends GetxController {
  late final AccountingRepository repository;
  final accounts = <Account>[].obs;
  final calculator = Rxn<FinancialCalculator>();
  final snapshots = <AccountBalanceSnapshot>[].obs;
  final latestSnapshots = <String, AccountBalanceSnapshot>{}.obs;

  @override
  void onInit() {
    repository = AccountingRepository(Get.find<AppDatabase>());
    reload();
    super.onInit();
  }

  Future<void> reload() async {
    accounts.value = await repository.accounts(includeArchived: true);
    calculator.value = await repository.calculator();
    final db = Get.find<AppDatabase>();
    final all = await db.select(db.accountBalanceSnapshots).get();
    final latest = <String, AccountBalanceSnapshot>{};
    for (final snapshot in all.where((s) => !s.isDeleted)) {
      final previous = latest[snapshot.accountId];
      if (previous == null ||
          snapshot.date.isAfter(previous.date) ||
          (snapshot.date.isAtSameMomentAs(previous.date) &&
              snapshot.createdAt.isAfter(previous.createdAt))) {
        latest[snapshot.accountId] = snapshot;
      }
    }
    latestSnapshots.value = latest;
  }

  List<Account> get activeAccounts =>
      accounts.where((a) => !a.isArchived).toList();
  Future<void> loadSnapshots(String id) async {
    snapshots.value = await repository.snapshots(id);
  }
}
