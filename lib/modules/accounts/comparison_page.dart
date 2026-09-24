import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';

class ComparisonPage extends StatefulWidget {
  const ComparisonPage({super.key});
  @override
  State<ComparisonPage> createState() => _ComparisonPageState();
}

class _ComparisonPageState extends State<ComparisonPage> {
  DateTime from = DateTime.now().subtract(const Duration(days: 30));
  DateTime to = DateTime.now();
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Balance Comparison')),
    body: Obx(() {
      final calc = Get.find<AccountController>().calculator.value;
      if (calc == null) return const Center(child: CircularProgressIndicator());
      final c = calc.compare(from, to);
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            title: const Text('From'),
            subtitle: Text(DateHelper.formatDate(from)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pick(true),
          ),
          ListTile(
            title: const Text('To'),
            subtitle: Text(DateHelper.formatDate(to)),
            trailing: const Icon(Icons.calendar_today),
            onTap: () => _pick(false),
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Opening net worth', c.opening.netWorth),
                  _row('Closing net worth', c.closing.netWorth),
                  const Divider(),
                  _row('Change', c.change, bold: true),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text('What changed', style: Theme.of(context).textTheme.titleLarge),
          _row('Income', c.income),
          _row('Expense', -c.expense),
          _row('Net cash flow', c.netCashFlow, bold: true),
          _row('Money lent (asset conversion)', c.moneyLent),
          _row('Lend repayments', c.lendRepayments),
          _row('Borrowed (offset by liability)', c.borrowed),
          _row('Borrow repayments', c.borrowRepayments),
          _row('Transfers (between accounts)', c.transfers),
          _row('Adjustments', c.adjustments),
          const Divider(),
          _row(
            'Unexplained / unassigned difference',
            c.unexplained,
            bold: true,
          ),
          const SizedBox(height: 12),
          const Text(
            'Transfers, lending, and borrowing do not by themselves change net worth. '
            'Legacy unassigned records and excluded accounts can create a difference.',
          ),
        ],
      );
    }),
  );

  Widget _row(String label, int cents, {bool bold = false}) => ListTile(
    dense: true,
    title: Text(
      label,
      style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
    ),
    trailing: Text(
      CurrencyHelper.formatAmount(Money.bdt(cents)),
      style: TextStyle(fontWeight: bold ? FontWeight.bold : null),
    ),
  );

  Future<void> _pick(bool first) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: first ? from : to,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (first) {
          from = picked;
          if (to.isBefore(from)) to = from;
        } else {
          to = picked;
          if (from.isAfter(to)) from = to;
        }
      });
    }
  }
}
