import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../income_expense/expense_controller.dart';
import '../income_expense/income_controller.dart';
import '../lend_borrow/lend_borrow_controller.dart';
import 'dashboard_controller.dart';
import 'dashboard_summary.dart';
import 'dashboard_activity.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _activityKey = GlobalKey();
  late final DashboardController controller;

  @override
  void initState() {
    super.initState();
    controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());
  }

  void _showActivity(DashboardTransactionTab tab) {
    controller.selectTab(tab, currentMonthOnly: true);
    final context = _activityKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 300),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'EXPTRA',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                DateFormat('MMMM yyyy').format(now),
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Obx(() {
        final calc = controller.calculator;
        if (calc == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final position = calc.position();
        final month = controller.currentMonth(now)!;
        // These reads keep the activity list in sync with edits made in existing forms.
        final incomeCount = Get.find<IncomeController>().incomes.length;
        final expenseCount = Get.find<ExpenseController>().expenses.length;
        final lendCount = Get.find<LendBorrowController>().lends.length;
        final borrowCount = Get.find<LendBorrowController>().borrows.length;
        final hasEntries =
            incomeCount +
                expenseCount +
                lendCount +
                borrowCount +
                calc.transfers.length >
            0;
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeroCard(position: position),
              const SizedBox(height: 20),
              MonthlySummary(
                month: month,
                onIncome: () => _showActivity(DashboardTransactionTab.income),
                onExpense: () => _showActivity(DashboardTransactionTab.expense),
              ),
              const SizedBox(height: 20),
              const QuickActions(),
              const SizedBox(height: 20),
              RecentActivity(
                key: _activityKey,
                controller: controller,
                hasEntries: hasEntries,
              ),
            ],
          ),
        );
      }),
    );
  }
}
