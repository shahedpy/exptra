import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';
import 'account_detail_page.dart';
import 'comparison_page.dart';
import 'financial_history_page.dart';

class FinancialReportsPage extends StatelessWidget {
  const FinancialReportsPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Financial Reports')),
    body: Obx(() {
      final calc = Get.find<AccountController>().calculator.value;
      if (calc == null) return const Center(child: CircularProgressIndicator());
      final accounts = calc.accounts.where((a) => !a.isDeleted).toList();
      final institutions = <String, int>{};
      final allocation = <String, int>{};
      for (final a in accounts) {
        final value = calc.balanceOf(a);
        final institution = a.institutionName.isEmpty
            ? 'Other'
            : a.institutionName;
        institutions.update(
          institution,
          (v) => v + value,
          ifAbsent: () => value,
        );
        allocation.update(a.type, (v) => v + value, ifAbsent: () => value);
      }
      final now = DateTime.now();
      final months = List.generate(
        6,
        (i) => DateTime(now.year, now.month - i, 1),
      );
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.compare_arrows),
            title: const Text('Balance change between dates'),
            onTap: () => Get.to(() => const ComparisonPage()),
          ),
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search financial history'),
            onTap: () => Get.to(() => const FinancialHistoryPage()),
          ),
          _title(context, 'Account balances'),
          for (final a in accounts)
            ListTile(
              title: Text(
                '${a.institutionName.isEmpty ? '' : '${a.institutionName} • '}${a.name}',
              ),
              trailing: _money(calc.balanceOf(a)),
              onTap: () => Get.to(() => AccountDetailPage(accountId: a.id)),
            ),
          _title(context, 'Institution balances'),
          for (final entry in institutions.entries)
            ListTile(title: Text(entry.key), trailing: _money(entry.value)),
          _title(context, 'Asset allocation'),
          for (final entry in allocation.entries)
            ListTile(title: Text(entry.key), trailing: _money(entry.value)),
          _title(context, 'Money to receive'),
          for (final l in calc.lends.where(
            (l) => !l.isDeleted && calc.outstandingLend(l) > 0,
          ))
            ListTile(
              title: Text(l.personName),
              trailing: _money(calc.outstandingLend(l)),
            ),
          _title(context, 'Money to pay'),
          for (final b in calc.borrows.where(
            (b) => !b.isDeleted && calc.outstandingBorrow(b) > 0,
          ))
            ListTile(
              title: Text(b.personName),
              trailing: _money(calc.outstandingBorrow(b)),
            ),
          _title(context, 'Monthly income / expense / net cash flow'),
          for (final month in months)
            Builder(
              builder: (context) {
                final end = DateTime(month.year, month.month + 1, 0);
                final start = month.subtract(const Duration(days: 1));
                final c = calc.compare(start, end.isAfter(now) ? now : end);
                return ListTile(
                  title: Text(DateHelper.formatMonthYear(month)),
                  subtitle: Text(
                    'Income ${CurrencyHelper.formatAmount(Money.bdt(c.income))}  •  '
                    'Expense ${CurrencyHelper.formatAmount(Money.bdt(c.expense))}',
                  ),
                  trailing: _money(c.netCashFlow),
                );
              },
            ),
          _title(context, 'Net worth history'),
          for (final month in months)
            Builder(
              builder: (context) {
                final end = DateTime(month.year, month.month + 1, 0);
                return ListTile(
                  title: Text(DateHelper.formatMonthYear(month)),
                  trailing: _money(
                    calc
                        .position(through: end.isAfter(now) ? now : end)
                        .netWorth,
                  ),
                );
              },
            ),
        ],
      );
    }),
  );

  Widget _title(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
    child: Text(title, style: Theme.of(context).textTheme.titleMedium),
  );
  Widget _money(int cents) =>
      Text(CurrencyHelper.formatAmount(Money.bdt(cents)));
}
