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
            final settled = entry.isSettled;
            final settledLabel = isLend ? 'Paid' : 'Returned';
            final avatarColor = settled
                ? Colors.grey.shade400
                : (isLend ? Colors.orange : Colors.blue);

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
                    backgroundColor: avatarColor,
                    child: Icon(
                      isLend
                          ? Icons.call_made_rounded
                          : Icons.call_received_rounded,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    entry.personName,
                    style: TextStyle(
                      decoration: settled
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: settled ? Colors.grey : null,
                    ),
                  ),
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
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        CurrencyHelper.formatAmount(entry.amount),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: settled ? Colors.grey : null,
                          decoration: settled
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 4),
                      GestureDetector(
                        onTap: () =>
                            controller.toggleSettled(entry.id, entry.isSettled),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: settled
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: settled
                                  ? Colors.green.shade400
                                  : Colors.grey.shade400,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                settled
                                    ? Icons.check_circle_rounded
                                    : Icons.radio_button_unchecked_rounded,
                                size: 12,
                                color: settled
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                settledLabel,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: settled
                                      ? Colors.green.shade700
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
