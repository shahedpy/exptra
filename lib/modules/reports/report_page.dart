import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/helpers.dart';
import 'report_controller.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ReportController());
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: Obx(
        () => Column(
          children: [
            _buildSummaryCard(theme, controller),
            _buildDataTypeSelector(controller),
            _buildTypeSelector(controller),
            if (controller.selectedType.value != ReportType.monthWise)
              _buildMonthSelector(controller),
            Expanded(child: _buildReportList(theme, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(ThemeData theme, ReportController controller) {
    return Card(
      margin: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Row(
          children: [
            Expanded(
              child: _summaryItem(
                title: 'Total',
                value: CurrencyHelper.formatAmount(
                  controller.totalAmount.value,
                ),
              ),
            ),
            Expanded(
              child: _summaryItem(
                title: 'Transactions',
                value: controller.totalTransactions.value.toString(),
              ),
            ),
            Expanded(
              child: _summaryItem(
                title: 'Type',
                value: _shortTypeLabel(
                  controller.selectedType.value,
                  controller.selectedDataType.value,
                ),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem({
    required String title,
    required String value,
    bool alignEnd = false,
  }) {
    final alignment = alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start;
    return Column(
      crossAxisAlignment: alignment,
      children: [
        Text(title, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          textAlign: alignEnd ? TextAlign.right : TextAlign.left,
        ),
      ],
    );
  }

  Widget _buildTypeSelector(ReportController controller) {
    final selectedDataType = controller.selectedDataType.value;
    final isExpense = selectedDataType == ReportDataType.expense;
    final isIncome = selectedDataType == ReportDataType.income;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.defaultPadding,
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ReportType>(
              segments: [
                ButtonSegment<ReportType>(
                  value: ReportType.monthWise,
                  label: Text('Month'),
                  icon: Icon(Icons.calendar_month_rounded),
                ),
                ButtonSegment<ReportType>(
                  value: ReportType.categoryWise,
                  label: Text(
                    isExpense
                        ? 'Category'
                        : isIncome
                        ? 'Source'
                        : 'Person',
                  ),
                  icon: Icon(
                    isExpense
                        ? Icons.category_rounded
                        : isIncome
                        ? Icons.account_balance_wallet_rounded
                        : Icons.person_rounded,
                  ),
                ),
                ButtonSegment<ReportType>(
                  value: ReportType.dailyWise,
                  label: Text('Daily'),
                  icon: Icon(Icons.view_day_rounded),
                ),
              ],
              selected: {controller.selectedType.value},
              onSelectionChanged: (types) {
                if (types.isNotEmpty) {
                  controller.changeType(types.first);
                }
              },
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTypeSelector(ReportController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        0,
        AppConstants.defaultPadding,
        8,
      ),
      child: SegmentedButton<ReportDataType>(
        segments: const [
          ButtonSegment<ReportDataType>(
            value: ReportDataType.expense,
            label: Text('Exp'),
            icon: Icon(Icons.remove_circle_outline_rounded),
          ),
          ButtonSegment<ReportDataType>(
            value: ReportDataType.income,
            label: Text('Inc'),
            icon: Icon(Icons.add_circle_outline_rounded),
          ),
          ButtonSegment<ReportDataType>(
            value: ReportDataType.lend,
            label: Text('Len'),
            icon: Icon(Icons.call_made_rounded),
          ),
          ButtonSegment<ReportDataType>(
            value: ReportDataType.borrow,
            label: Text('Bor'),
            icon: Icon(Icons.call_received_rounded),
          ),
        ],
        selected: {controller.selectedDataType.value},
        onSelectionChanged: (types) {
          if (types.isNotEmpty) {
            controller.changeDataType(types.first);
          }
        },
        showSelectedIcon: false,
      ),
    );
  }

  Widget _buildMonthSelector(ReportController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.defaultPadding,
        8,
        AppConstants.defaultPadding,
        0,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: controller.previousMonth,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Center(
              child: Text(
                DateHelper.formatMonthYear(controller.selectedMonth.value),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            onPressed: controller.canMoveToNextMonth
                ? controller.nextMonth
                : null,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildReportList(ThemeData theme, ReportController controller) {
    final items = controller.activeReport;
    if (items.isEmpty) {
      return Center(
        child: Text(
          'No data for ${controller.reportTitle.toLowerCase()}',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    final maxAmount = items
        .map((item) => item.amount)
        .fold<double>(0, (prev, current) => current > prev ? current : prev);

    return ListView.builder(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      itemCount: items.length,
      itemBuilder: (_, index) {
        final item = items[index];
        final progress = maxAmount <= 0 ? 0.0 : item.amount / maxAmount;
        final color = controller.colorForItem(item, theme);

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    Text(
                      CurrencyHelper.formatAmount(item.amount),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(height: 6),
                Text(
                  '${item.transactionCount} transaction(s)',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _shortTypeLabel(ReportType type, ReportDataType dataType) {
    switch (type) {
      case ReportType.monthWise:
        return 'Month';
      case ReportType.categoryWise:
        if (dataType == ReportDataType.expense) {
          return 'Category';
        }
        if (dataType == ReportDataType.income) {
          return 'Source';
        }
        return 'Person';
      case ReportType.dailyWise:
        return 'Daily';
    }
  }
}
