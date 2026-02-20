import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Income Sources'), elevation: 0),
      body: Obx(
        () => controller.isLoading.value
            ? const Center(child: CircularProgressIndicator())
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                buildDefaultDragHandles: false,
                itemCount: controller.incomeSources.length,
                onReorder: controller.reorderIncomeSources,
                itemBuilder: (_, index) {
                  final source = controller.incomeSources[index];
                  return Card(
                    key: ValueKey(source.id),
                    margin: const EdgeInsets.only(
                      bottom: AppConstants.defaultPadding,
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: ColorHelper.getColorFromInt(
                          source.color,
                        ),
                      ),
                      title: Text(source.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Edit'),
                                onTap: () => _editSource(source),
                              ),
                              PopupMenuItem(
                                child: const Text(
                                  'Delete',
                                  style: TextStyle(color: Colors.red),
                                ),
                                onTap: () =>
                                    controller.deleteIncomeSource(source.id),
                              ),
                            ],
                          ),
                          ReorderableDragStartListener(
                            index: index,
                            child: const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 8),
                              child: Icon(Icons.drag_handle),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSource,
        child: const Icon(Icons.add),
      ),
    );
  }

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
