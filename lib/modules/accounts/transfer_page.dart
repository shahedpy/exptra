import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import 'account_controller.dart';
import 'account_selector.dart';
import '../../core/widgets/app_ui.dart';
import '../../data/services/financial_calculator.dart';

class TransferPage extends StatefulWidget {
  const TransferPage({super.key});
  @override
  State<TransferPage> createState() => _TransferPageState();
}

class _TransferPageState extends State<TransferPage> {
  final key = GlobalKey<FormState>();
  final amount = TextEditingController();
  final fee = TextEditingController(text: '0');
  final note = TextEditingController();
  String? from, to;
  DateTime date = DateTime.now();
  bool saving = false;

  @override
  void dispose() {
    amount.dispose();
    fee.dispose();
    note.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!key.currentState!.validate() || saving) return;
    if (from == null || to == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Choose both accounts')));
      return;
    }
    if (from == to) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Choose different accounts')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      final controller = Get.find<AccountController>();
      await controller.repository.transfer(
        fromId: from!,
        toId: to!,
        amount: CurrencyHelper.parseAmount(amount.text),
        fee: CurrencyHelper.parseAmount(fee.text),
        note: note.text.trim(),
        date: date,
      );
      await controller.reload();
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$error')));
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Transfer Money')),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Transfers move money between your own accounts and are not counted as income or expense.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          AccountSelector(
            value: from,
            label: 'From',
            helperText: 'Source account',
            onChanged: (v) => setState(() {
              from = v;
              if (to == v) to = null;
            }),
          ),
          _balance(context, from),
          Center(
            child: IconButton(
              tooltip: 'Swap accounts',
              icon: const Icon(Icons.swap_vert_rounded),
              onPressed: from == null || to == null
                  ? null
                  : () => setState(() {
                      final old = from;
                      from = to;
                      to = old;
                    }),
            ),
          ),
          AccountSelector(
            value: to,
            label: 'To',
            helperText: 'Destination account',
            excludeId: from,
            onChanged: (v) => setState(() => to = v),
          ),
          _balance(context, to),
          const SizedBox(height: 16),
          AppAmountField(controller: amount),
          const SizedBox(height: 16),
          AppAmountField(
            controller: fee,
            label: 'Fee (optional expense)',
            validator: (v) =>
                double.tryParse((v ?? '').replaceAll(',', '')) == null ||
                    CurrencyHelper.parseAmount(v!) < 0
                ? 'Enter a nonnegative fee'
                : null,
          ),
          const SizedBox(height: 16),
          AppDateField(
            label: 'Transfer Date',
            date: date,
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: date,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => date = picked);
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: note,
            decoration: const InputDecoration(labelText: 'Note (optional)'),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving ? null : save,
              child: const Text('Transfer Money'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _balance(BuildContext context, String? id) {
    if (id == null) return const SizedBox.shrink();
    final controller = Get.find<AccountController>();
    final account = controller.activeAccounts
        .where((a) => a.id == id)
        .firstOrNull;
    final calc = controller.calculator.value;
    if (account == null || calc == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4, left: 4),
      child: Text(
        'Current balance: ${CurrencyHelper.formatAmount(Money.bdt(calc.balanceOf(account)))}',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
