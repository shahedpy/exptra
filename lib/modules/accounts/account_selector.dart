import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_ui.dart';
import '../../core/db/app_database.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';

class AccountSelector extends StatelessWidget {
  final String? value;
  final ValueChanged<String?> onChanged;
  final String label;
  final String? excludeId;
  final String? helperText;
  const AccountSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.excludeId,
    this.helperText,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();
    return Obx(() {
      final accounts = controller.activeAccounts
          .where((a) => a.id != excludeId)
          .toList();
      final selected = accounts.where((a) => a.id == value).firstOrNull;
      return FormField<String>(
        key: ValueKey('$label-$value-$excludeId'),
        initialValue: selected?.id,
        validator: (_) => accounts.isNotEmpty && selected == null
            ? 'Select an account'
            : null,
        builder: (field) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: accounts.isEmpty
                  ? null
                  : () async {
                      final result = await _pick(context, controller, accounts);
                      if (result != null) {
                        onChanged(result);
                        field.didChange(result);
                      }
                    },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  errorText: field.errorText,
                  helperText: accounts.isEmpty
                      ? 'Add an account first'
                      : selected == null
                      ? helperText ?? 'Choose an account'
                      : null,
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                child: Text(
                  selected == null
                      ? 'Select account'
                      : '${selected.institutionName.isEmpty ? '' : '${selected.institutionName} • '}${selected.name}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Future<String?> _pick(
    BuildContext context,
    AccountController controller,
    List<Account> accounts,
  ) {
    String query = '';
    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final calculator = controller.calculator.value;
          final visible = accounts
              .where(
                (a) =>
                    '${a.institutionName} ${a.name} ${calculator?.typeNameOf(a) ?? a.type}'
                        .toLowerCase()
                        .contains(query.toLowerCase()),
              )
              .toList();
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              0,
              16,
              MediaQuery.viewInsetsOf(context).bottom + 16,
            ),
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .65,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select Account',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    autofocus: false,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search accounts',
                    ),
                    onChanged: (v) => setSheetState(() => query = v),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      itemCount: visible.length,
                      itemBuilder: (_, i) {
                        final a = visible[i];
                        final calc = controller.calculator.value;
                        return AppFinancialListRow(
                          icon: Icons.account_balance_wallet_outlined,
                          title: a.name,
                          subtitle: a.institutionName.isEmpty
                              ? (calc?.typeNameOf(a) ?? a.type)
                              : '${a.institutionName} • ${calc?.typeNameOf(a) ?? a.type}',
                          amount: calc == null
                              ? ''
                              : CurrencyHelper.formatAmount(
                                  Money.bdt(calc.balanceOf(a)),
                                ),
                          onTap: () => Navigator.pop(sheetContext, a.id),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
