import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/utils/helpers.dart';
import 'account_controller.dart';
import 'account_selector.dart';

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
    appBar: AppBar(title: const Text('Transfer')),
    body: Form(
      key: key,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AccountSelector(
            value: from,
            label: 'From account',
            onChanged: (v) => setState(() => from = v),
          ),
          const SizedBox(height: 16),
          AccountSelector(
            value: to,
            label: 'To account',
            excludeId: from,
            onChanged: (v) => setState(() => to = v),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: amount,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
            validator: ValidationHelper.validateAmount,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: fee,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Fee (expense)',
              prefixText: '৳ ',
              border: OutlineInputBorder(),
            ),
            validator: (v) =>
                double.tryParse(v ?? '') == null || double.parse(v!) < 0
                ? 'Enter a nonnegative fee'
                : null,
          ),
          ListTile(
            title: const Text('Transfer date'),
            subtitle: Text(DateHelper.formatDate(date)),
            trailing: const Icon(Icons.calendar_today),
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
          TextFormField(
            controller: note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: saving ? null : save,
            child: const Text('Save Transfer'),
          ),
        ],
      ),
    ),
  );
}
