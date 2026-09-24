import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'account_controller.dart';

class AccountSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? excludeId;
  const AccountSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.excludeId,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();
    return Obx(() {
      final accounts = controller.activeAccounts
          .where((a) => a.id != excludeId)
          .toList();
      final selected = accounts.any((a) => a.id == value) ? value : null;
      return DropdownButtonFormField<String>(
        initialValue: selected,
        isExpanded: true,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          helperText: accounts.isEmpty
              ? 'Add an account first'
              : value == null
              ? 'Unassigned records do not affect account balances'
              : null,
        ),
        items: accounts
            .map(
              (a) => DropdownMenuItem(
                value: a.id,
                child: Text(
                  '${a.institutionName.isEmpty ? '' : '${a.institutionName} • '}${a.name}',
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        validator: accounts.isEmpty
            ? null
            : (v) => v == null ? 'Select an account' : null,
      );
    });
  }
}
