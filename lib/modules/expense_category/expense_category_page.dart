import 'package:flutter/material.dart';
import '../../core/widgets/master_data_list.dart';
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
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Obx(
    () => MasterDataList<ExpenseCategory>(
      title: 'Expense Categories',
      singular: 'Category',
      emptyMessage:
          'No expense categories yet. Add one to use in expense forms.',
      icon: Icons.category_outlined,
      items: controller.categories.toList(),
      loading: controller.isLoading.value,
      idOf: (x) => x.id,
      nameOf: (x) => x.name,
      colorOf: (x) => ColorHelper.getColorFromInt(x.color),
      onAdd: _addCategory,
      onEdit: _editCategory,
      onDelete: _confirmDeleteCategory,
      onReorder: controller.reorderCategories,
    ),
  );

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
                            color: isSelected
                                ? Theme.of(context).colorScheme.onSurface
                                : Theme.of(context).colorScheme.outline,
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
