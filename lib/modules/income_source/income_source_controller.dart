import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/db/app_database.dart';
import '../../data/repositories/income_source_repository.dart';

class IncomeSourceController extends GetxController {
  late final IncomeSourceRepository repository;
  final incomeSources = <IncomeSource>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    repository = IncomeSourceRepository(Get.find<AppDatabase>());
    loadIncomeSources();
    super.onInit();
  }

  Future<void> loadIncomeSources() async {
    try {
      isLoading.value = true;
      final loadedSources = await repository.getAllIncomeSources();

      if (loadedSources.isEmpty) {
        await seedDefaultIncomeSources();
      } else {
        incomeSources.value = loadedSources;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> seedDefaultIncomeSources() async {
    for (final source in AppConstants.defaultIncomeSources) {
      await repository.insertIncomeSource(
        name: source['name'] as String,
        color: source['color'] as int,
      );
    }
    incomeSources.value = await repository.getAllIncomeSources();
  }

  Future<void> addIncomeSource({
    required String name,
    required int color,
  }) async {
    try {
      await repository.insertIncomeSource(name: name, color: color);
      await loadIncomeSources();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add income source: $e');
    }
  }

  Future<void> updateIncomeSource({
    required String id,
    required String name,
    required int color,
  }) async {
    try {
      await repository.updateIncomeSource(id: id, name: name, color: color);
      await loadIncomeSources();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update income source: $e');
    }
  }

  Future<void> deleteIncomeSource(String id) async {
    try {
      final incomeCount = await repository.getIncomeCountBySource(id);
      if (incomeCount > 0) {
        Get.snackbar(
          'Cannot Delete',
          'This source has $incomeCount income entr${incomeCount == 1 ? 'y' : 'ies'}. Delete them first.',
        );
        return;
      }

      await repository.softDelete(id);
      await loadIncomeSources();
      Get.snackbar('Success', 'Income source deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete income source: $e');
    }
  }

  Future<void> reorderIncomeSources(int oldIndex, int newIndex) async {
    if (oldIndex < 0 || oldIndex >= incomeSources.length) return;
    if (newIndex < 0 || newIndex > incomeSources.length) return;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }

    final updated = List<IncomeSource>.from(incomeSources);
    final moved = updated.removeAt(oldIndex);
    updated.insert(newIndex, moved);
    incomeSources.value = updated;

    try {
      await repository.reorderIncomeSources(updated.map((e) => e.id).toList());
    } catch (e) {
      await loadIncomeSources();
      Get.snackbar('Error', 'Failed to reorder income sources: $e');
    }
  }

  IncomeSource? getIncomeSourceById(String id) {
    try {
      return incomeSources.firstWhere((source) => source.id == id);
    } catch (e) {
      return null;
    }
  }
}
