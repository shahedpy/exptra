import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import '../../data/models/account_type_defaults.dart';
import 'account_controller.dart';
import 'account_form_page.dart';
import 'account_detail_page.dart';
import 'comparison_page.dart';
import 'transfer_page.dart';
import '../../core/widgets/app_ui.dart';

enum AccountTypeFilter { all, liquid, investment }

class AccountsPage extends StatelessWidget {
  final AccountTypeFilter accountFilter;
  const AccountsPage({super.key, this.accountFilter = AccountTypeFilter.all});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();
    return Scaffold(
      appBar: AppBar(
        title: Text(switch (accountFilter) {
          AccountTypeFilter.all => 'Accounts',
          AccountTypeFilter.liquid => 'Available Accounts',
          AccountTypeFilter.investment => 'Investments',
        }),
        actions: [
          IconButton(
            tooltip: 'Compare dates',
            icon: const Icon(Icons.compare_arrows),
            onPressed: () => Get.to(() => const ComparisonPage()),
          ),
          IconButton(
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh),
            onPressed: controller.reload,
          ),
        ],
      ),
      body: Obx(() {
        final calculator = controller.calculator.value;
        if (calculator == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final position = calculator.position();
        final groups = <String, List<Account>>{};
        for (final account in controller.activeAccounts.where((account) {
          final classification = calculator.classificationOf(account);
          return accountFilter == AccountTypeFilter.all ||
              (account.includeInNetWorth &&
                  (accountFilter == AccountTypeFilter.investment
                      ? classification == AccountTypeClass.investment
                      : classification == AccountTypeClass.liquid));
        })) {
          groups
              .putIfAbsent(
                account.institutionName.isEmpty
                    ? 'Other'
                    : account.institutionName,
                () => [],
              )
              .add(account);
        }
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (accountFilter == AccountTypeFilter.all)
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Assets',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyHelper.formatAmount(
                            Money.bdt(
                              position.bankAndCash +
                                  position.investments +
                                  position.otherAssets +
                                  position.receivables +
                                  position.excludedAssets,
                            ),
                          ),
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      const Divider(height: 20),
                      _row('Available', position.bankAndCash),
                      _row('Investments', position.investments),
                      if (position.otherAssets != 0)
                        _row('Other assets', position.otherAssets),
                      _row('Money to Receive', position.receivables),
                      _row('Money to Pay', -position.liabilities),
                      _row('Net Worth', position.netWorth, bold: true),
                      if (position.excludedAssets != 0)
                        _row('Excluded accounts', position.excludedAssets),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            AppActionRow(
              firstLabel: 'Add Account',
              firstIcon: Icons.add_rounded,
              onFirst: () => Get.to(() => const AccountFormPage()),
              secondLabel: 'Transfer',
              secondIcon: Icons.swap_horiz_rounded,
              onSecond: () => Get.to(() => const TransferPage()),
            ),
            const SizedBox(height: 20),
            if (groups.isEmpty)
              AppEmptyState(
                title: accountFilter == AccountTypeFilter.all
                    ? 'No accounts yet'
                    : 'No accounts in this view',
                message: accountFilter == AccountTypeFilter.all
                    ? 'Add a bank, cash, mobile wallet, FDR or DPS account to track where your money is.'
                    : 'Try another account view.',
                actionLabel: accountFilter == AccountTypeFilter.all
                    ? 'Add Account'
                    : null,
                onAction: accountFilter == AccountTypeFilter.all
                    ? () => Get.to(() => const AccountFormPage())
                    : null,
              ),
            ...groups.entries.map(
              (group) => _group(
                context,
                controller,
                calculator,
                group.key,
                group.value,
              ),
            ),
            if (accountFilter == AccountTypeFilter.all &&
                controller.accounts.any((a) => a.isArchived))
              ExpansionTile(
                title: const Text('Archived accounts'),
                children: [
                  for (final a in controller.accounts.where(
                    (a) => a.isArchived,
                  ))
                    ListTile(
                      title: Text('${a.institutionName} ${a.name}'),
                      subtitle: Text(
                        CurrencyHelper.formatAmount(
                          Money.bdt(calculator.balanceOf(a)),
                        ),
                      ),
                      onTap: () =>
                          Get.to(() => AccountDetailPage(accountId: a.id)),
                    ),
                ],
              ),
          ],
        );
      }),
    );
  }

  Widget _group(
    BuildContext context,
    AccountController controller,
    FinancialCalculator calculator,
    String name,
    List<Account> accounts,
  ) {
    final theme = Theme.of(context);
    final total = accounts.fold<int>(
      0,
      (sum, a) => sum + calculator.balanceOf(a),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Flexible(
                  child: AppTrailingAmount(
                    CurrencyHelper.formatAmount(Money.bdt(total)),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Card(
            color: theme.colorScheme.surfaceContainerLow,
            elevation: 0,
            child: Column(
              children: [
                for (final a in accounts)
                  InkWell(
                    onTap: () =>
                        Get.to(() => AccountDetailPage(accountId: a.id)),
                    onLongPress: () => _accountMenu(context, controller, a),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall,
                                ),
                                Builder(
                                  builder: (context) {
                                    final snapshot =
                                        controller.latestSnapshots[a.id];
                                    final unresolved =
                                        snapshot != null &&
                                        Money.cents(snapshot.difference) != 0 &&
                                        !calculator.adjustments.any(
                                          (x) =>
                                              !x.isDeleted &&
                                              x.snapshotId == snapshot.id,
                                        );
                                    final details = <String>[];
                                    details.add(calculator.typeNameOf(a));
                                    if (snapshot != null) {
                                      details.add(
                                        'Last checked ${DateHelper.formatDate(snapshot.date)}',
                                      );
                                      if (unresolved) {
                                        details.add('Difference to review');
                                      }
                                    }
                                    return Text(
                                      details.join(' • '),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: AppTrailingAmount(
                              CurrencyHelper.formatAmount(
                                Money.bdt(calculator.balanceOf(a)),
                              ),
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            tooltip: 'Account options',
                            icon: const Icon(Icons.more_vert),
                            onPressed: () =>
                                _accountMenu(context, controller, a),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _accountMenu(
    BuildContext context,
    AccountController controller,
    Account account,
  ) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () {
                Navigator.pop(context);
                Get.to(() => AccountFormPage(account: account));
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () async {
                Navigator.pop(context);
                await controller.repository.archiveAccount(account.id, true);
                await controller.reload();
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_upward),
              title: const Text('Move up'),
              onTap: () async {
                Navigator.pop(context);
                await _move(controller, account, -1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.arrow_downward),
              title: const Text('Move down'),
              onTap: () async {
                Navigator.pop(context);
                await _move(controller, account, 1);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _move(
    AccountController controller,
    Account account,
    int offset,
  ) async {
    final rows = controller.activeAccounts;
    final index = rows.indexWhere((a) => a.id == account.id);
    final next = index + offset;
    if (index < 0 || next < 0 || next >= rows.length) return;
    final copy = [...rows];
    final removed = copy.removeAt(index);
    copy.insert(next, removed);
    await controller.repository.reorder(copy);
    await controller.reload();
  }

  Widget _row(String label, int cents, {bool bold = false}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
        Flexible(
          child: AppTrailingAmount(
            CurrencyHelper.formatAmount(Money.bdt(cents)),
            style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
          ),
        ),
      ],
    ),
  );
}
