import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/db/app_database.dart';
import 'lend_borrow_controller.dart';
import '../accounts/account_selector.dart';
import '../../data/services/financial_calculator.dart';
import '../../core/widgets/app_ui.dart';
import '../accounts/account_controller.dart';

class LendBorrowPage extends StatefulWidget {
  final int initialIndex;
  final bool outstandingOnly;
  const LendBorrowPage({
    super.key,
    this.initialIndex = 0,
    this.outstandingOnly = false,
  });

  @override
  State<LendBorrowPage> createState() => _LendBorrowPageState();
}

class _LendBorrowPageState extends State<LendBorrowPage> {
  late int _selectedIndex; // 0 = All, 1 = Lend, 2 = Borrow

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LendBorrowController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lend & Borrow')),
      body: Column(
        children: [
          Obx(() {
            final receive = controller.lends.fold<int>(
              0,
              (sum, e) =>
                  sum +
                  (controller.outstandingLends[e.id] ?? Money.cents(e.amount)),
            );
            final pay = controller.borrows.fold<int>(
              0,
              (sum, e) =>
                  sum +
                  (controller.outstandingBorrows[e.id] ??
                      Money.cents(e.amount)),
            );
            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceCard(
                          label: 'To Receive',
                          amount: receive,
                          icon: Icons.call_received_rounded,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _BalanceCard(
                          label: 'To Pay',
                          amount: pay,
                          icon: Icons.call_made_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  AppActionRow(
                    firstLabel: 'Add Lend',
                    firstIcon: Icons.add_rounded,
                    onFirst: () => Get.toNamed(AppRoutes.addLend),
                    secondLabel: 'Add Borrow',
                    secondIcon: Icons.add_rounded,
                    onSecond: () => Get.toNamed(AppRoutes.addBorrow),
                  ),
                ],
              ),
            );
          }),
          // Button Segment
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 12,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                spacing: 6,
                children: [
                  for (final (index, label) in [
                    (0, 'All'),
                    (1, 'To Receive'),
                    (2, 'To Pay'),
                  ])
                    ChoiceChip(
                      label: Text(label),
                      selected: _selectedIndex == index,
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => setState(() => _selectedIndex = index),
                    ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              final lends = controller.lends
                  .where(
                    (entry) =>
                        !widget.outstandingOnly ||
                        (controller.outstandingLends[entry.id] ??
                                Money.cents(entry.amount)) >
                            0,
                  )
                  .toList();
              final borrows = controller.borrows
                  .where(
                    (entry) =>
                        !widget.outstandingOnly ||
                        (controller.outstandingBorrows[entry.id] ??
                                Money.cents(entry.amount)) >
                            0,
                  )
                  .toList();
              final allEmpty = lends.isEmpty && borrows.isEmpty;

              if (allEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: AppEmptyState(
                    title: 'No lend or borrow records',
                    message: widget.outstandingOnly
                        ? 'No outstanding lend or borrow records.'
                        : 'Add a lend or borrowing to track money to receive or pay.',
                    actionLabel: 'Add Lend',
                    onAction: () => Get.toNamed(AppRoutes.addLend),
                  ),
                );
              }

              if (_selectedIndex == 0) {
                // All - combine both lists
                final all = <dynamic>[...lends, ...borrows]
                  ..sort((a, b) {
                    final aDate = a is Lend
                        ? a.lendDate
                        : (a as Borrow).borrowDate;
                    final bDate = b is Lend
                        ? b.lendDate
                        : (b as Borrow).borrowDate;
                    return bDate.compareTo(aDate);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: all.length,
                  itemBuilder: (_, index) =>
                      _buildEntryTile(controller, all[index]),
                );
              }

              if (_selectedIndex == 1) {
                final lendList = [...lends]
                  ..sort((a, b) => b.lendDate.compareTo(a.lendDate));

                if (lendList.isEmpty) {
                  return Center(
                    child: Text(
                      'No lend entries yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: lendList.length,
                  itemBuilder: (_, index) =>
                      _buildEntryTile(controller, lendList[index]),
                );
              }

              final borrowList = [...borrows]
                ..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

              if (borrowList.isEmpty) {
                return Center(
                  child: Text(
                    'No borrow entries yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: borrowList.length,
                itemBuilder: (_, index) =>
                    _buildEntryTile(controller, borrowList[index]),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(LendBorrowController controller, dynamic entry) {
    final isLend = entry is Lend;
    final String id = entry.id;
    final String personName = entry.personName;
    final double amount = entry.amount;
    final String? note = entry.note;
    final String? accountId = entry.accountId;
    final DateTime date = isLend ? entry.lendDate : entry.borrowDate;
    final outstanding = isLend
        ? controller.outstandingLends[id] ?? Money.cents(amount)
        : controller.outstandingBorrows[id] ?? Money.cents(amount);
    final type = isLend
        ? LendBorrowController.typeLend
        : LendBorrowController.typeBorrow;
    final status = outstanding == 0
        ? 'Paid'
        : outstanding < Money.cents(amount)
        ? 'Partial'
        : 'Outstanding';
    final theme = Theme.of(context);
    final account = accountId == null
        ? null
        : Get.find<AccountController>().accounts
              .where((a) => a.id == accountId)
              .firstOrNull;
    final accountName = account == null
        ? 'Unassigned account'
        : '${account.institutionName.isEmpty ? '' : '${account.institutionName} '}${account.name}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Card(
        color: theme.colorScheme.surfaceContainerLow,
        elevation: 0,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Get.toNamed(
            isLend ? AppRoutes.addLend : AppRoutes.addBorrow,
            arguments: entry,
          ),
          onLongPress: () => Get.dialog(
            AlertDialog(
              title: const Text('Delete entry?'),
              content: Text('The record for $personName will be removed.'),
              actions: [
                TextButton(onPressed: Get.back, child: const Text('Cancel')),
                TextButton(
                  onPressed: () {
                    controller.deleteEntry(id, type);
                    Get.back();
                  },
                  child: Text(
                    'Delete',
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    isLend
                        ? Icons.call_made_rounded
                        : Icons.call_received_rounded,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        personName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      Text(
                        '${isLend ? 'Lend' : 'Borrow'} • $status',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        '${isLend ? 'From' : 'Into'} $accountName',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (outstanding < Money.cents(amount) && outstanding > 0)
                        Text(
                          'Original ${CurrencyHelper.formatAmount(amount)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      if (note?.isNotEmpty == true)
                        Text(
                          note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      Text(
                        DateHelper.formatDate(date),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      AppTrailingAmount(
                        CurrencyHelper.formatAmount(Money.bdt(outstanding)),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (outstanding > 0)
                        TextButton(
                          onPressed: () => _showRepayment(
                            controller,
                            id: id,
                            type: type,
                            outstanding: outstanding,
                            originalDate: date,
                          ),
                          child: Text(isLend ? 'Receive' : 'Repay'),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showRepayment(
    LendBorrowController controller, {
    required String id,
    required String type,
    required int outstanding,
    required DateTime originalDate,
  }) async {
    String amountText = Money.bdt(outstanding).toStringAsFixed(2);
    String? accountId;
    DateTime date = DateTime.now();
    final formKey = GlobalKey<FormState>();
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          scrollable: true,
          title: Text(
            type == LendBorrowController.typeLend
                ? 'Receive repayment'
                : 'Repay borrowing',
          ),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Outstanding: ${CurrencyHelper.formatAmount(Money.bdt(outstanding))}',
                ),
                const SizedBox(height: 12),
                AccountSelector(
                  value: accountId,
                  label: type == LendBorrowController.typeLend
                      ? 'Receive into account'
                      : 'Pay from account',
                  onChanged: (v) => setDialogState(() => accountId = v),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  initialValue: amountText,
                  onChanged: (value) => amountText = value,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Amount',
                    prefixText: '৳ ',
                  ),
                  validator: (v) {
                    final parsed = double.tryParse(v ?? '');
                    if (parsed == null ||
                        Money.cents(parsed) <= 0 ||
                        Money.cents(parsed) > outstanding) {
                      return 'Enter an amount up to the outstanding balance';
                    }
                    return null;
                  },
                ),
                ListTile(
                  title: Text(DateHelper.formatDate(date)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: originalDate,
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) setDialogState(() => date = picked);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState!.validate() && accountId != null) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
    if (saved == true && accountId != null) {
      try {
        await controller.repay(
          id: id,
          type: type,
          accountId: accountId!,
          amount: double.parse(amountText),
          date: date,
        );
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Repayment recorded')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
  }
}

class _BalanceCard extends StatelessWidget {
  final String label;
  final int amount;
  final IconData icon;
  const _BalanceCard({
    required this.label,
    required this.amount,
    required this.icon,
  });
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                CurrencyHelper.formatAmount(Money.bdt(amount)),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
