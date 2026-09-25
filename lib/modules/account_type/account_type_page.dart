import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/widgets/master_data_list.dart';
import '../../data/models/account_type_defaults.dart';
import 'account_type_controller.dart';
import 'account_type_form_page.dart';

class AccountTypePage extends StatelessWidget {
  const AccountTypePage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountTypeController>();
    return Obx(
      () => MasterDataList<AccountType>(
        title: 'Account Types',
        singular: 'Account Type',
        emptyMessage:
            'Account types define the kinds of accounts you can create.',
        icon: Icons.account_tree_outlined,
        items: controller.types.toList(),
        loading: controller.isLoading.value,
        idOf: (x) => x.id,
        nameOf: (x) => x.name,
        subtitleOf: (x) => AccountTypeClass.label(x.classification),
        onAdd: () => Get.to(() => const AccountTypeFormPage()),
        onEdit: (x) => Get.to(() => AccountTypeFormPage(type: x)),
        onDelete: (x) => _confirmDelete(context, controller, x),
        onReorder: controller.reorder,
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    AccountTypeController controller,
    AccountType type,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete account type?'),
        content: Text(
          '“${type.name}” will no longer appear when adding accounts.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    final deleted = await controller.delete(type);
    if (!deleted && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Account type is being used by one or more accounts and cannot be deleted.',
          ),
        ),
      );
    }
  }
}
