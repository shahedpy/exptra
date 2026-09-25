import 'package:flutter/material.dart';
import '../../core/widgets/master_data_list.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import 'income_source_controller.dart';

class IncomeSourcePage extends StatefulWidget {
  const IncomeSourcePage({super.key});

  @override
  State<IncomeSourcePage> createState() => _IncomeSourcePageState();
}

class _IncomeSourcePageState extends State<IncomeSourcePage> {
  final controller = Get.put(IncomeSourceController());
  final _nameController = TextEditingController();
  late Color _selectedColor;

  @override
  void initState() {
    super.initState();
    _selectedColor = const Color(0xFF4CAF50);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirmDeleteSource(IncomeSource source) {
    Get.dialog(
      AlertDialog(
        title: const Text('Delete Income Source'),
        content: Text('Are you sure you want to delete "${source.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              controller.deleteIncomeSource(source.id);
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
    () => MasterDataList<IncomeSource>(
      title: 'Income Sources',
      singular: 'Income Source',
      emptyMessage: 'No income sources yet. Add one to use in income forms.',
      icon: Icons.payments_outlined,
      items: controller.incomeSources.toList(),
      loading: controller.isLoading.value,
      idOf: (x) => x.id,
      nameOf: (x) => x.name,
      colorOf: (x) => ColorHelper.getColorFromInt(x.color),
      onAdd: _addSource,
      onEdit: _editSource,
      onDelete: _confirmDeleteSource,
      onReorder: controller.reorderIncomeSources,
    ),
  );

  void _addSource() {
    _nameController.clear();
    _selectedColor = const Color(0xFF4CAF50);
    _showSourceDialog('Add Source', isEdit: false);
  }

  void _editSource(IncomeSource source) {
    _nameController.text = source.name;
    _selectedColor = ColorHelper.getColorFromInt(source.color);
    _showSourceDialog('Edit Source', isEdit: true, source: source);
  }

  void _showSourceDialog(
    String title, {
    required bool isEdit,
    IncomeSource? source,
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
                    labelText: 'Source Name',
                    hintText: 'e.g., Salary, Freelance',
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
                  Get.snackbar('Error', 'Source name is required');
                  return;
                }

                if (isEdit && source != null) {
                  controller.updateIncomeSource(
                    id: source.id,
                    name: name,
                    color: ColorHelper.getColorAsInt(_selectedColor),
                  );
                } else {
                  controller.addIncomeSource(
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
