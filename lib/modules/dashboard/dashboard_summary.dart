import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../data/services/financial_calculator.dart';
import '../accounts/accounts_page.dart';
import '../accounts/transfer_page.dart';
import '../lend_borrow/lend_borrow_page.dart';

class DashboardHeroCard extends StatelessWidget {
  final FinancialPosition position;
  const DashboardHeroCard({super.key, required this.position});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Card(
      color: scheme.primaryContainer,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth',
              style: theme.titleMedium?.copyWith(
                color: scheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 2),
            _AmountText(
              amount: position.netWorth,
              style: theme.headlineLarge?.copyWith(
                color: scheme.onPrimaryContainer,
                fontWeight: FontWeight.w700,
              ),
              height: 42,
            ),
            const SizedBox(height: 12),
            Divider(
              height: 1,
              color: scheme.onPrimaryContainer.withValues(alpha: .2),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'Available',
                    icon: Icons.account_balance_wallet_outlined,
                    amount: position.bankAndCash,
                    onTap: () => Get.to(
                      () => const AccountsPage(
                        accountFilter: AccountTypeFilter.liquid,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroMetric(
                    label: 'Investments',
                    icon: Icons.trending_up_rounded,
                    amount: position.investments,
                    onTap: () => Get.to(
                      () => const AccountsPage(
                        accountFilter: AccountTypeFilter.investment,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: _HeroMetric(
                    label: 'To Receive',
                    icon: Icons.call_received_rounded,
                    amount: position.receivables,
                    onTap: () => Get.to(
                      () => const LendBorrowPage(
                        initialIndex: 1,
                        outstandingOnly: true,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _HeroMetric(
                    label: 'To Pay',
                    icon: Icons.call_made_rounded,
                    amount: position.liabilities,
                    onTap: () => Get.to(
                      () => const LendBorrowPage(
                        initialIndex: 2,
                        outstandingOnly: true,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  final String label;
  final IconData icon;
  final int amount;
  final VoidCallback onTap;
  const _HeroMetric({
    required this.label,
    required this.icon,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: '$label, ${CurrencyHelper.formatAmount(Money.bdt(amount))}',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 16,
                    color: scheme.onPrimaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              _AmountText(
                amount: amount,
                style: theme.titleMedium?.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
                height: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MonthlySummary extends StatelessWidget {
  final PeriodComparison month;
  final VoidCallback onIncome;
  final VoidCallback onExpense;
  const MonthlySummary({
    super.key,
    required this.month,
    required this.onIncome,
    required this.onExpense,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This Month',
          style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _MonthlyMetric(
                label: 'Income',
                icon: Icons.add_circle_outline_rounded,
                amount: month.income,
                onTap: onIncome,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MonthlyMetric(
                label: 'Expense',
                icon: Icons.remove_circle_outline_rounded,
                amount: month.expense,
                onTap: onExpense,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Net Cash Flow',
                  style: theme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  CurrencyHelper.formatSignedAmount(
                    Money.bdt(month.netCashFlow),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MonthlyMetric extends StatelessWidget {
  final String label;
  final IconData icon;
  final int amount;
  final VoidCallback onTap;
  const _MonthlyMetric({
    required this.label,
    required this.icon,
    required this.amount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context).textTheme;
    return Card(
      color: scheme.surfaceContainerLow,
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.labelLarge?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              _AmountText(
                amount: amount,
                style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                height: 25,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuickActions extends StatelessWidget {
  const QuickActions({super.key});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        SizedBox(
        height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _QuickAction(
                label: 'Income',
                icon: Icons.add_rounded,
                onTap: () => Get.toNamed(AppRoutes.addIncome),
              ),
              _QuickAction(
                label: 'Expense',
                icon: Icons.remove_rounded,
                onTap: () => Get.toNamed(AppRoutes.addExpense),
              ),
              _QuickAction(
                label: 'Transfer',
                icon: Icons.swap_horiz_rounded,
                onTap: () => Get.to(() => const TransferPage()),
              ),
              _QuickAction(
                label: 'Lend',
                icon: Icons.call_made_rounded,
                onTap: () => Get.toNamed(AppRoutes.addLend),
              ),
              _QuickAction(
                label: 'Borrow',
                icon: Icons.call_received_rounded,
                onTap: () => Get.toNamed(AppRoutes.addBorrow),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ActionChip(
        avatar: Icon(icon, size: 18),
        label: Text(label),
        onPressed: onTap,
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  final int amount;
  final TextStyle? style;
  final double height;
  const _AmountText({
    required this.amount,
    required this.style,
    required this.height,
  });
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Align(
        alignment: Alignment.centerLeft,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            CurrencyHelper.formatAmount(Money.bdt(amount)),
            maxLines: 1,
            style: style,
          ),
        ),
      ),
    );
  }
}
