import 'package:get/get.dart';
import '../../../data/repositories/expense_category_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/constants/app_constants.dart';

class ExpenseCategoryController extends GetxController {
  late final ExpenseCategoryRepository repository;
  final categories = <Category>[].obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    repository = ExpenseCategoryRepository(Get.find<AppDatabase>());
    loadCategories();
    super.onInit();
  }

  Future<void> loadCategories() async {
    try {
      isLoading.value = true;
      final loadedCategories = await repository.getAllCategories();

      // If no categories exist, seed with defaults
      if (loadedCategories.isEmpty) {
        await seedDefaultCategories();
      } else {
        categories.value = loadedCategories;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> seedDefaultCategories() async {
    for (final cat in AppConstants.defaultCategories) {
      await repository.insertCategory(
        name: cat['name'] as String,
        color: cat['color'] as int,
      );
    }
    categories.value = await repository.getAllCategories();
  }

  Future<void> addCategory({required String name, required int color}) async {
    try {
      await repository.insertCategory(name: name, color: color);
      await loadCategories();
    } catch (e) {
      Get.snackbar('Error', 'Failed to add category: $e');
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required int color,
  }) async {
    try {
      await repository.updateCategory(id: id, name: name, color: color);
      await loadCategories();
    } catch (e) {
      Get.snackbar('Error', 'Failed to update category: $e');
    }
  }

  Future<void> deleteCategory(String id) async {
    try {
      // Check if category has expenses
      final expenseCount = await repository.getExpenseCountByCategory(id);
      if (expenseCount > 0) {
        Get.snackbar(
          'Cannot Delete',
          'This category has $expenseCount expense(s). Delete them first.',
        );
        return;
      }

      await repository.softDelete(id);
      await loadCategories();
      Get.snackbar('Success', 'Category deleted');
    } catch (e) {
      Get.snackbar('Error', 'Failed to delete category: $e');
    }
  }

  Category? getCategoryById(String id) {
    try {
      return categories.firstWhere((cat) => cat.id == id);
    } catch (e) {
      return null;
    }
  }
}
