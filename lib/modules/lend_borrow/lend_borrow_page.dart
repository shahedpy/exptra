import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import 'lend_borrow_controller.dart';

class LendBorrowPage extends StatelessWidget {
  const LendBorrowPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LendBorrowController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lend & Borrow')),
      body: Obx(() {
        if (controller.entries.isEmpty) {
          return Center(
            child: Text(
              'No lend/borrow entries yet',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          itemCount: controller.entries.length,
          itemBuilder: (_, index) {
            final entry = controller.entries[index];
            final isLend = entry.type == LendBorrowController.typeLend;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: InkWell(
                onLongPress: () {
                  Get.dialog(
                    AlertDialog(
                      title: const Text('Delete Entry'),
                      content: const Text(
                        'Are you sure you want to delete this entry?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Get.back(),
                          child: const Text('Cancel'),
                        ),
                        TextButton(
                          onPressed: () {
                            controller.deleteEntry(entry.id);
                            Get.back();
                          },
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: ListTile(
                  contentPadding: const EdgeInsets.all(
                    AppConstants.defaultPadding,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: isLend ? Colors.orange : Colors.blue,
                    child: Icon(
                      isLend
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(entry.personName),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isLend ? 'Lend' : 'Borrow',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      if (entry.note != null && entry.note!.isNotEmpty)
                        Text(
                          entry.note!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      Text(
                        DateHelper.formatDate(entry.transactionDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  trailing: Text(
                    CurrencyHelper.formatAmount(entry.amount),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      }),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addLendBorrow),
        child: const Icon(Icons.add),
      ),
    );
  }
}
