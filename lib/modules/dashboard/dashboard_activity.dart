import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/db/app_database.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import '../accounts/account_controller.dart';
import '../expense_category/expense_category_controller.dart';
import '../income_source/income_source_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import 'dashboard_controller.dart';

class RecentActivity extends StatelessWidget {
  final DashboardController controller;
  final bool hasEntries;
  const RecentActivity({
    super.key,
    required this.controller,
    required this.hasEntries,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    final entries = controller.entries();
    final visible = controller.showAll.value
        ? entries
        : entries.take(6).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Recent Activity',
                style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (entries.length > 6)
              TextButton(
                onPressed: () => controller.showAll.toggle(),
                child: Text(controller.showAll.value ? 'Show less' : 'See all'),
              ),
          ],
        ),
        SizedBox(
        height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              for (final (tab, label) in [
                (DashboardTransactionTab.all, 'All'),
                (DashboardTransactionTab.income, 'Income'),
                (DashboardTransactionTab.expense, 'Expense'),
                (DashboardTransactionTab.transfer, 'Transfer'),
                (DashboardTransactionTab.lendBorrow, 'Lend/Borrow'),
              ])
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(label),
                    selected: controller.selectedTransactionTab.value == tab,
                    onSelected: (_) => controller.selectTab(tab),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
        ),
        if (controller.monthOnly.value)
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => controller.monthOnly.value = false,
              icon: const Icon(Icons.close_rounded, size: 16),
              label: const Text('This month'),
            ),
          ),
        const SizedBox(height: 6),
        if (entries.isEmpty)
          Card(
            color: scheme.surfaceContainerLow,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasEntries
                        ? 'No activity in this view'
                        : 'No transactions yet',
                    style: theme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    hasEntries
                        ? 'Try another filter or month.'
                        : 'Add your first income or expense to start tracking your হিসাব.',
                    style: theme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  if (!hasEntries) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.addIncome),
                          child: const Text('Add Income'),
                        ),
                        TextButton(
                          onPressed: () => Get.toNamed(AppRoutes.addExpense),
                          child: const Text('Add Expense'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          )
        else
          for (final entry in visible)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: _ActivityTile(entry: entry),
            ),
      ],
    );
  }
}

class _ActivityTile extends StatelessWidget {
  final DashboardEntry entry;
  const _ActivityTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    final calc = Get.find<AccountController>().calculator.value;
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    String title;
    String type;
    String? note;
    String? accountId;
    String? status;
    int amount;
    IconData icon;
    VoidCallback? onTap;
    switch (entry.type) {
      case DashboardEntryType.income:
        final item = entry.record as Income;
        title =
            Get.find<IncomeSourceController>()
                .getIncomeSourceById(item.sourceId ?? '')
                ?.name ??
            item.source ??
            'Income';
        type = 'Income';
        note = item.note;
        accountId = item.accountId;
        amount = Money.cents(item.amount);
        icon = Icons.add_rounded;
        onTap = () => Get.toNamed(AppRoutes.addIncome, arguments: item);
      case DashboardEntryType.expense:
        final item = entry.record as Expense;
        title =
            Get.find<ExpenseCategoryController>()
                .getCategoryById(item.categoryId)
                ?.name ??
            'Expense';
        type = 'Expense';
        note = item.note;
        accountId = item.accountId;
        amount = -Money.cents(item.amount);
        icon = Icons.remove_rounded;
        onTap = () => Get.toNamed(AppRoutes.addExpense, arguments: item);
      case DashboardEntryType.transfer:
        final item = entry.record as AccountTransfer;
        final from =
            calc?.accounts
                .where((a) => a.id == item.fromAccountId)
                .firstOrNull
                ?.name ??
            'Account';
        final to =
            calc?.accounts
                .where((a) => a.id == item.toAccountId)
                .firstOrNull
                ?.name ??
            'Account';
        title = '$from → $to';
        type = 'Transfer';
        note = item.note;
        accountId = null;
        amount = Money.cents(item.amount);
        icon = Icons.swap_horiz_rounded;
        onTap = null;
      case DashboardEntryType.lend:
        final item = entry.record as Lend;
        title = item.personName;
        type = 'Lend';
        note = item.note;
        accountId = item.accountId;
        amount = -Money.cents(item.amount);
        icon = Icons.call_made_rounded;
        final remaining =
            calc?.outstandingLend(item) ??
            Get.find<LendBorrowController>().outstandingLends[item.id] ??
            amount.abs();
        status = remaining == 0
            ? 'Paid'
            : remaining < amount.abs()
            ? 'Partially paid'
            : 'Outstanding';
        onTap = () => Get.toNamed(AppRoutes.addLend, arguments: item);
      case DashboardEntryType.borrow:
        final item = entry.record as Borrow;
        title = item.personName;
        type = 'Borrow';
        note = item.note;
        accountId = item.accountId;
        amount = Money.cents(item.amount);
        icon = Icons.call_received_rounded;
        final remaining =
            calc?.outstandingBorrow(item) ??
            Get.find<LendBorrowController>().outstandingBorrows[item.id] ??
            amount;
        status = remaining == 0
            ? 'Returned'
            : remaining < amount
            ? 'Partially returned'
            : 'Outstanding';
        onTap = () => Get.toNamed(AppRoutes.addBorrow, arguments: item);
    }
    final accountName = accountId == null
        ? null
        : calc?.accounts.where((a) => a.id == accountId).firstOrNull?.name;
    final amountText = entry.type == DashboardEntryType.transfer
        ? CurrencyHelper.formatAmount(Money.bdt(amount))
        : CurrencyHelper.formatSignedAmount(Money.bdt(amount));
    return Card(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: scheme.surfaceContainerHighest,
                child: Icon(icon, size: 18, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      [type, ?accountName].join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      DateHelper.formatDate(entry.date),
                      style: theme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (note != null && note.trim().isNotEmpty)
                      Text(
                        note,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 128),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      amountText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.end,
                    ),
                    if (status != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          status,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.end,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
