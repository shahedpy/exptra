import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'expense_category_controller.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../core/constants/app_constants.dart';

class ExpenseCategoryPage extends StatefulWidget {
  const ExpenseCategoryPage({super.key});

  @override
  State<ExpenseCategoryPage> createState() => _ExpenseCategoryPageState();
}

class _ExpenseCategoryPageState extends State<ExpenseCategoryPage> {
  final controller = Get.put(ExpenseCategoryController());
  final _nameController = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = const Color(0xFFFF6B6B);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmDeleteCategory(ExpenseCategory category) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteCategory(category.id);
              Get.back();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Expense Categories'), elevation: 0),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                buildDefaultDragHandles: false,
                itemCount: controller.categories.length,
                onReorder: controller.reorderCategories,
                itemBuilder: (_, index) {
                  final category = controller.categories[index];
                  return Card(
                    key: ValueKey(category.id),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ColorHelper.getColorFromInt(
                          category.color,
                        ),
                      ),
                      title: Text(category.name),
                      onTap: () => _editCategory(category),
                      onLongPress: () => _confirmDeleteCategory(category),
                      trailing: ReorderableDragStartListener(
                        index: index,
                        child: Icon(Icons.drag_handle),
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addCategory,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _addCategory() {
    _nameController.clear();
    _selectedColor = const Color(0xFFFF6B6B);
    _showCategoryDialog('Add Expense Category', isEdit: false);
  }

  void _editCategory(ExpenseCategory category) {
    _nameController.text = category.name;
    _selectedColor = ColorHelper.getColorFromInt(category.color);
    _showCategoryDialog(
      'Edit Expense Category',
      isEdit: true,
      category: category,
    );
  }

  void _showCategoryDialog(
    String title, {
    required bool isEdit,
    ExpenseCategory? category,
  }) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Expense Category Name',
                    hintText: 'e.g., Food, Transport',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(
                        AppConstants.defaultBorderRadius,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: AppConstants.defaultPadding),
                const Text('Select Color:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ColorHelper.getCategoryColors().map((color) {
                    final isSelected =
                        _selectedColor.toARGB32() == color.toARGB32();
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedColor = color;
                        });
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? Colors.black : Colors.grey,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) {
                  Get.snackbar('Error', 'Category name is required');
                  return;
                }

                if (isEdit && category != null) {
                  controller.updateCategory(
                    id: category.id,
                    name: name,
                    color: ColorHelper.getColorAsInt(_selectedColor),
                  );
                } else {
                  controller.addCategory(
                    name: name,
                    color: ColorHelper.getColorAsInt(_selectedColor),
                  );
                }
                Navigator.pop(context);
              },
              child: Text(isEdit ? 'Update' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
