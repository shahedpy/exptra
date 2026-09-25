import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../core/widgets/app_ui.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';
import 'account_form_page.dart';

class AccountDetailPage extends StatefulWidget {
  final String accountId;
  const AccountDetailPage({super.key, required this.accountId});
  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  String type = 'all', query = '';
  DateTimeRange? range;
  final controller = Get.find<AccountController>();

  @override
  void initState() {
    super.initState();
    controller.loadSnapshots(widget.accountId);
  }

  @override
  Widget build(BuildContext context) => Obx(() {
    final calc = controller.calculator.value;
    if (calc == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final account = controller.accounts.firstWhere(
      (a) => a.id == widget.accountId,
    );
    final allEntries = calc
        .entriesFor(account.id)
        .where((e) => !e.date.isBefore(account.openingBalanceDate))
        .toList();
    final running = <String, int>{};
    var balance = Money.cents(account.openingBalance);
    for (final e in allEntries) {
      balance += e.amount;
      running['${e.type}:${e.id}'] = balance;
    }
    final entries = allEntries
        .where(
          (e) =>
              (type == 'all' || e.type == type) &&
              (range == null ||
                  (!e.date.isBefore(range!.start) &&
                      !e.date.isAfter(
                        DateTime(
                          range!.end.year,
                          range!.end.month,
                          range!.end.day,
                          23,
                          59,
                          59,
                        ),
                      ))) &&
              (query.isEmpty ||
                  '${e.title} ${e.note ?? ''} ${e.person ?? ''} ${Money.bdt(e.amount)}'
                      .toLowerCase()
                      .contains(query.toLowerCase())),
        )
        .toList()
        .reversed
        .toList();
    final snapshots = controller.snapshots
        .where((s) => s.accountId == account.id)
        .toList();
    final latest = snapshots.isEmpty ? null : snapshots.first;
    bool resolved(AccountBalanceSnapshot snapshot) => calc.adjustments.any(
      (a) => !a.isDeleted && a.snapshotId == snapshot.id,
    );
    return Scaffold(
      appBar: AppBar(
        title: Text('${account.institutionName} ${account.name}'.trim()),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit account',
            onPressed: () => Get.to(() => AccountFormPage(account: account)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calculated balance',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  Text(
                    CurrencyHelper.formatAmount(
                      Money.bdt(calc.balanceOf(account)),
                    ),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text('${calc.typeNameOf(account)} • ${account.currency}'),
                  if (latest != null)
                    Text(
                      'Last checked ${DateHelper.formatDate(latest.date)} • Difference ${CurrencyHelper.formatAmount(latest.difference)}',
                    ),
                  if (latest != null &&
                      Money.cents(latest.difference) != 0 &&
                      !resolved(latest))
                    const Text(
                      'Reconciliation difference recorded',
                      style: TextStyle(color: Colors.orange),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              TextButton.icon(
                onPressed: () => _record(account),
                icon: const Icon(Icons.fact_check),
                label: const Text('Record actual balance'),
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDateRange: range,
                  );
                  if (picked != null) setState(() => range = picked);
                },
                icon: const Icon(Icons.date_range),
                label: const Text('Dates'),
              ),
            ],
          ),
          TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search note, person, amount',
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final t in [
                  'all',
                  'income',
                  'expense',
                  'transfer',
                  'lend',
                  'borrow',
                  'adjustment',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: ChoiceChip(
                      label: Text(t[0].toUpperCase() + t.substring(1)),
                      selected: type == t,
                      onSelected: (_) => setState(() => type = t),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (entries.isEmpty)
            const ListTile(title: Text('No matching transactions')),
          for (final entry in entries)
            AppFinancialListRow(
              icon: _icon(entry.type),
              title: entry.title,
              subtitle:
                  '${DateHelper.formatDate(entry.date)}${entry.note == null || entry.note!.isEmpty ? '' : ' • ${entry.note}'}\nRunning: ${CurrencyHelper.formatAmount(Money.bdt(running['${entry.type}:${entry.id}'] ?? 0))}',
              amount:
                  '${entry.amount >= 0 ? '+' : ''}${CurrencyHelper.formatAmount(Money.bdt(entry.amount))}',
            ),
          const Divider(),
          Text(
            'Balance checks',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          for (final s in snapshots)
            ListTile(
              title: Text(
                '${DateHelper.formatDate(s.date)}  Actual ${CurrencyHelper.formatAmount(s.actualBalance)}',
              ),
              subtitle: Text(
                'Calculated ${CurrencyHelper.formatAmount(s.calculatedBalance)}  •  Difference ${CurrencyHelper.formatAmount(s.difference)}',
              ),
              trailing: Money.cents(s.difference) == 0 || resolved(s)
                  ? null
                  : TextButton(
                      onPressed: () => _adjust(s),
                      child: const Text('Adjust'),
                    ),
            ),
        ],
      ),
    );
  });

  IconData _icon(String type) => switch (type) {
    'income' => Icons.add_circle_outline,
    'expense' => Icons.remove_circle_outline,
    'transfer' => Icons.swap_horiz,
    'lend' => Icons.call_made,
    'borrow' => Icons.call_received,
    _ => Icons.tune,
  };

  Future<void> _record(Account account) async {
    final amount = TextEditingController();
    final note = TextEditingController();
    var date = DateTime.now();
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Actual balance'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amount,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Actual balance',
                  prefixText: '৳ ',
                ),
              ),
              ListTile(
                title: Text(DateHelper.formatDate(date)),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: date,
                    firstDate: account.openingBalanceDate,
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setDialogState(() => date = picked);
                },
              ),
              TextField(
                controller: note,
                decoration: const InputDecoration(labelText: 'Note'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Record'),
            ),
          ],
        ),
      ),
    );
    if (result == true && double.tryParse(amount.text) != null) {
      try {
        final snapshot = await controller.repository.recordSnapshot(
          accountId: account.id,
          date: date,
          actual: double.parse(amount.text),
          note: note.text.trim(),
        );
        await controller.loadSnapshots(account.id);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Balance check saved'),
            content: Text(
              'Calculated: ${CurrencyHelper.formatAmount(snapshot.calculatedBalance)}\n'
              'Actual: ${CurrencyHelper.formatAmount(snapshot.actualBalance)}\n'
              'Difference: ${CurrencyHelper.formatAmount(snapshot.difference)}',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
              if (Money.cents(snapshot.difference) != 0)
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _adjust(snapshot);
                  },
                  child: const Text('Create Balance Adjustment'),
                ),
            ],
          ),
        );
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('$error')));
        }
      }
    }
    amount.dispose();
    note.dispose();
  }

  Future<void> _adjust(AccountBalanceSnapshot snapshot) async {
    try {
      await controller.repository.adjustSnapshot(snapshot);
      await controller.reload();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Balance adjustment created')),
        );
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
