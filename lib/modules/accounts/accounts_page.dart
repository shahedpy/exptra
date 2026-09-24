import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';
import 'account_form_page.dart';
import 'account_detail_page.dart';
import 'comparison_page.dart';
import 'transfer_page.dart';

class AccountsPage extends StatelessWidget {
  const AccountsPage({super.key});
  @override
  Widget build(BuildContext context) {
    final controller = Get.find<AccountController>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hisab'),
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
        for (final account in controller.activeAccounts) {
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
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Financial Position',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _row('Net Worth', position.netWorth, bold: true),
                    const Divider(),
                    _row('Bank & Cash', position.bankAndCash),
                    _row('Investments', position.investments),
                    _row('Money to Receive', position.receivables),
                    _row('Money to Pay', -position.liabilities),
                    if (position.excludedAssets != 0)
                      _row('Excluded accounts', position.excludedAssets),
                  ],
                ),
              ),
            ),
            if (controller.activeAccounts.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Add your first account to start tracking balances. Old transactions remain unassigned.',
                ),
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
            if (controller.accounts.any((a) => a.isArchived))
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
            const SizedBox(height: 80),
          ],
        );
      }),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'transfer',
            tooltip: 'Transfer',
            onPressed: () => Get.to(() => const TransferPage()),
            child: const Icon(Icons.swap_horiz),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'account',
            tooltip: 'Add account',
            onPressed: () => Get.to(() => const AccountFormPage()),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _group(
    BuildContext context,
    AccountController controller,
    FinancialCalculator calculator,
    String name,
    List<Account> accounts,
  ) {
    final total = accounts.fold<int>(0, (s, a) => s + calculator.balanceOf(a));
    return Card(
      child: Column(
        children: [
          ListTile(
            title: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Text(CurrencyHelper.formatAmount(Money.bdt(total))),
          ),
          for (final a in accounts)
            ListTile(
              title: Text(a.name),
              subtitle: Builder(
                builder: (context) {
                  final snapshot = controller.latestSnapshots[a.id];
                  final unresolved =
                      snapshot != null &&
                      Money.cents(snapshot.difference) != 0 &&
                      !calculator.adjustments.any(
                        (x) => !x.isDeleted && x.snapshotId == snapshot.id,
                      );
                  return Text(
                    snapshot == null
                        ? a.type
                        : '${a.type} • Last checked ${DateHelper.formatDate(snapshot.date)}${unresolved ? ' • Difference to review' : ''}',
                  );
                },
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    CurrencyHelper.formatAmount(
                      Money.bdt(calculator.balanceOf(a)),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Account options',
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _accountMenu(context, controller, a),
                  ),
                ],
              ),
              onTap: () => Get.to(() => AccountDetailPage(accountId: a.id)),
              onLongPress: () => _accountMenu(context, controller, a),
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
        Text(
          CurrencyHelper.formatAmount(Money.bdt(cents)),
          style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
        ),
      ],
    ),
  );
}
