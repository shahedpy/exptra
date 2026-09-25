import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../data/repositories/account_type_repository.dart';
import '../accounts/account_controller.dart';

class AccountTypeController extends GetxController {
  late final AccountTypeRepository repository;
  final types = <AccountType>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    repository = AccountTypeRepository(Get.find<AppDatabase>());
    load();
    super.onInit();
  }

  Future<void> load() async {
    isLoading.value = true;
    try {
      types.value = await repository.all();
    } finally {
      isLoading.value = false;
    }
  }

  Future<AccountType> save({
    String? id,
    required String name,
    required String classification,
    required bool requiresInstitution,
  }) async {
    final type = id == null
        ? await repository.create(
            name: name,
            classification: classification,
            requiresInstitution: requiresInstitution,
          )
        : await repository.update(
            id: id,
            name: name,
            classification: classification,
            requiresInstitution: requiresInstitution,
          );
    await load();
    if (Get.isRegistered<AccountController>()) {
      await Get.find<AccountController>().reload();
    }
    return type;
  }

  Future<bool> delete(AccountType type) async {
    final deleted = await repository.deleteIfUnused(type.id);
    if (deleted) await load();
    return deleted;
  }

  Future<void> reorder(int oldIndex, int newIndex) async {
    if (oldIndex < 0 ||
        oldIndex >= types.length ||
        newIndex < 0 ||
        newIndex > types.length) {
      return;
    }
    final updated = [...types];
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    types.value = updated;
    try {
      await repository.reorder(updated.map((x) => x.id).toList());
    } catch (_) {
      await load();
      Get.snackbar('Could not reorder', 'Please try again.');
    }
  }
}
