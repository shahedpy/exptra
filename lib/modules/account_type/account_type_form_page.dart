import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/db/app_database.dart';
import '../../data/models/account_type_defaults.dart';
import 'account_type_controller.dart';

class AccountTypeFormPage extends StatefulWidget {
  final AccountType? type;
  const AccountTypeFormPage({super.key, this.type});
  @override
  State<AccountTypeFormPage> createState() => _AccountTypeFormPageState();
}

class _AccountTypeFormPageState extends State<AccountTypeFormPage> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  String classification = AccountTypeClass.liquid;
  bool requiresInstitution = false;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    final type = widget.type;
    if (type != null) {
      name.text = type.name;
      classification = type.classification;
      requiresInstitution = type.requiresInstitution;
    }
  }

  @override
  void dispose() {
    name.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!formKey.currentState!.validate() || saving) return;
    setState(() => saving = true);
    try {
      final type = await Get.find<AccountTypeController>().save(
        id: widget.type?.id,
        name: name.text.trim(),
        classification: classification,
        requiresInstitution: requiresInstitution,
      );
      if (mounted) Navigator.pop(context, type.id);
    } on StateError catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not save account type. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        widget.type == null ? 'Add Account Type' : 'Edit Account Type',
      ),
    ),
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          TextFormField(
            controller: name,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Name',
              hintText: 'e.g., Provident Fund',
            ),
            validator: (v) => v == null || v.trim().isEmpty
                ? 'Account type name is required'
                : null,
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: classification,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Financial Group'),
            items: AccountTypeClass.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(AccountTypeClass.label(value)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) setState(() => classification = value);
            },
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Requires Bank / Institution'),
            value: requiresInstitution,
            onChanged: (value) => setState(() => requiresInstitution = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 48,
            child: FilledButton(
              onPressed: saving ? null : save,
              child: Text(
                saving
                    ? 'Saving…'
                    : widget.type == null
                    ? 'Save Account Type'
                    : 'Save Changes',
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
