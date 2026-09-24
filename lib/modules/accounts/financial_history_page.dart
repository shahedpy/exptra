import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import 'account_controller.dart';
import 'account_detail_page.dart';

class FinancialHistoryPage extends StatefulWidget {
  const FinancialHistoryPage({super.key});
  @override
  State<FinancialHistoryPage> createState() => _FinancialHistoryPageState();
}

class _FinancialHistoryPageState extends State<FinancialHistoryPage> {
  String? accountId, institution, type, categoryId, sourceId, person;
  String query = '';
  DateTimeRange? range;
  final min = TextEditingController(), max = TextEditingController();
  List<ExpenseCategory> categories = [];
  List<IncomeSource> sources = [];

  @override
  void initState() {
    super.initState();
    final db = Get.find<AppDatabase>();
    Future.wait([
      db.select(db.expenseCategories).get(),
      db.select(db.incomeSources).get(),
    ]).then((rows) {
      if (mounted) {
        setState(() {
          categories = rows[0] as List<ExpenseCategory>;
          sources = rows[1] as List<IncomeSource>;
        });
      }
    });
  }

  @override
  void dispose() {
    min.dispose();
    max.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Financial History')),
    body: Obx(() {
      final calc = Get.find<AccountController>().calculator.value;
      if (calc == null) return const Center(child: CircularProgressIndicator());
      final accounts = calc.accounts.where((a) => !a.isDeleted).toList();
      final institutions =
          accounts
              .map((a) => a.institutionName)
              .where((s) => s.isNotEmpty)
              .toSet()
              .toList()
            ..sort();
      final people = <String>{
        ...calc.lends.map((e) => e.personName),
        ...calc.borrows.map((e) => e.personName),
      }.toList()..sort();
      final rows = <LedgerEntry>[];
      for (final a in accounts) {
        rows.addAll(calc.entriesFor(a.id));
      }
      final lower = double.tryParse(min.text);
      final upper = double.tryParse(max.text);
      final filtered = rows.where((e) {
        final a = accounts.firstWhere((a) => a.id == e.accountId);
        final absAmount = Money.bdt(e.amount.abs());
        return (accountId == null || e.accountId == accountId) &&
            (institution == null || a.institutionName == institution) &&
            (type == null || e.type == type) &&
            (categoryId == null || e.categoryId == categoryId) &&
            (sourceId == null || e.sourceId == sourceId) &&
            (person == null || e.person == person) &&
            (lower == null || absAmount >= lower) &&
            (upper == null || absAmount <= upper) &&
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
                '${e.title} ${e.note ?? ''} ${e.person ?? ''}'
                    .toLowerCase()
                    .contains(query.toLowerCase()));
      }).toList()..sort((a, b) => b.date.compareTo(a.date));
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Search note or text',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (v) => setState(() => query = v),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _dropdown(
                'Account',
                accountId,
                accounts
                    .map((a) => (a.id, '${a.institutionName} ${a.name}'.trim()))
                    .toList(),
                (v) => setState(() => accountId = v),
              ),
              _dropdown(
                'Institution',
                institution,
                institutions.map((s) => (s, s)).toList(),
                (v) => setState(() => institution = v),
              ),
              _dropdown(
                'Type',
                type,
                [
                  'income',
                  'expense',
                  'transfer',
                  'lend',
                  'borrow',
                  'adjustment',
                ].map((s) => (s, s)).toList(),
                (v) => setState(() => type = v),
              ),
              _dropdown(
                'Category',
                categoryId,
                categories
                    .where((c) => !c.isDeleted)
                    .map((c) => (c.id, c.name))
                    .toList(),
                (v) => setState(() => categoryId = v),
              ),
              _dropdown(
                'Source',
                sourceId,
                sources
                    .where((s) => !s.isDeleted)
                    .map((s) => (s.id, s.name))
                    .toList(),
                (v) => setState(() => sourceId = v),
              ),
              _dropdown(
                'Person',
                person,
                people.map((s) => (s, s)).toList(),
                (v) => setState(() => person = v),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: min,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Min amount'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: max,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max amount'),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              IconButton(
                tooltip: 'Date range',
                icon: const Icon(Icons.date_range),
                onPressed: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                    initialDateRange: range,
                  );
                  if (picked != null) setState(() => range = picked);
                },
              ),
            ],
          ),
          if (range != null)
            Text(
              '${DateHelper.formatDate(range!.start)} – ${DateHelper.formatDate(range!.end)}',
            ),
          Text(
            '${filtered.length} transactions',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          for (final e in filtered)
            ListTile(
              title: Text(e.title),
              subtitle: Text(
                '${DateHelper.formatDate(e.date)} • ${accounts.firstWhere((a) => a.id == e.accountId).name} • ${e.type}',
              ),
              trailing: Text(
                '${e.amount >= 0 ? '+' : ''}${CurrencyHelper.formatAmount(Money.bdt(e.amount))}',
              ),
              onTap: () =>
                  Get.to(() => AccountDetailPage(accountId: e.accountId)),
            ),
          if (filtered.isEmpty)
            const ListTile(title: Text('No matching transactions')),
        ],
      );
    }),
  );

  Widget _dropdown(
    String label,
    String? value,
    List<(String, String)> values,
    ValueChanged<String?> onChanged,
  ) => SizedBox(
    width: 155,
    child: DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      decoration: InputDecoration(labelText: label),
      items: [
        DropdownMenuItem<String>(value: null, child: Text('All $label')),
        for (final (id, text) in values)
          DropdownMenuItem(
            value: id,
            child: Text(text, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    ),
  );
}
