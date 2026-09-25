import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../utils/helpers.dart';

class AppEmptyState extends StatelessWidget {
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  const AppEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: theme.colorScheme.surfaceContainerLow,
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 8),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class AppAmountField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final bool prominent;
  const AppAmountField({
    super.key,
    required this.controller,
    this.label = 'Amount',
    this.validator,
    this.prominent = false,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    style: prominent ? Theme.of(context).textTheme.headlineSmall : null,
    decoration: InputDecoration(
      labelText: label,
      hintText: '0.00',
      prefixText: '${AppConstants.currencySymbol} ',
    ),
    validator: validator ?? ValidationHelper.validateAmount,
  );
}

class AppTrailingAmount extends StatelessWidget {
  final String amount;
  final TextStyle? style;
  const AppTrailingAmount(this.amount, {super.key, this.style});

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerRight,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(amount, textAlign: TextAlign.end, style: style),
    ),
  );
}

class AppFinancialListRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String amount;
  final IconData? icon;
  final VoidCallback? onTap;
  const AppFinancialListRow({
    super.key,
    required this.title,
    this.subtitle,
    required this.amount,
    this.icon,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyLarge,
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: AppTrailingAmount(
                amount,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class AppDateField extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const AppDateField({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(12),
    onTap: onTap,
    child: InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today_outlined),
      ),
      child: Text(DateHelper.formatDate(date)),
    ),
  );
}

class AppActionRow extends StatelessWidget {
  final String firstLabel;
  final IconData firstIcon;
  final VoidCallback onFirst;
  final String secondLabel;
  final IconData secondIcon;
  final VoidCallback onSecond;
  const AppActionRow({
    super.key,
    required this.firstLabel,
    required this.firstIcon,
    required this.onFirst,
    required this.secondLabel,
    required this.secondIcon,
    required this.onSecond,
  });

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final stack =
          constraints.maxWidth < 350 ||
          MediaQuery.textScalerOf(context).scale(14) > 17;
      final first = FilledButton.icon(
        onPressed: onFirst,
        icon: Icon(firstIcon, size: 18),
        label: Text(firstLabel),
      );
      final second = OutlinedButton.icon(
        onPressed: onSecond,
        icon: Icon(secondIcon, size: 18),
        label: Text(secondLabel),
      );
      if (stack) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [first, const SizedBox(height: 8), second],
        );
      }
      return Row(
        children: [
          Expanded(child: first),
          const SizedBox(width: 8),
          Expanded(child: second),
        ],
      );
    },
  );
}

class AppSectionTitle extends StatelessWidget {
  final String title;
  const AppSectionTitle(this.title, {super.key});
  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
  );
}
