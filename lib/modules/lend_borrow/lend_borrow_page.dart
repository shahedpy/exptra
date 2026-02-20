import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../core/constants/app_constants.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/helpers.dart';
import '../../core/db/app_database.dart';
import 'lend_borrow_controller.dart';

class LendBorrowPage extends StatefulWidget {
  const LendBorrowPage({super.key});

  @override
  State<LendBorrowPage> createState() => _LendBorrowPageState();
}

class _LendBorrowPageState extends State<LendBorrowPage> {
  int _selectedIndex = 0; // 0 = All, 1 = Lend, 2 = Borrow

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LendBorrowController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lend & Borrow')),
      body: Column(
        children: [
          // Button Segment
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.defaultPadding,
              vertical: 12,
            ),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment<int>(
                  value: 0,
                  label: Text('All'),
                  icon: Icon(Icons.list_alt_rounded),
                ),
                ButtonSegment<int>(
                  value: 1,
                  label: Text('Lend'),
                  icon: Icon(Icons.call_made_rounded),
                ),
                ButtonSegment<int>(
                  value: 2,
                  label: Text('Borrow'),
                  icon: Icon(Icons.call_received_rounded),
                ),
              ],
              selected: {_selectedIndex},
              showSelectedIcon: false,
              onSelectionChanged: (selected) {
                setState(() {
                  _selectedIndex = selected.first;
                });
              },
            ),
          ),

          // Content
          Expanded(
            child: Obx(() {
              final lends = controller.lends;
              final borrows = controller.borrows;
              final allEmpty = lends.isEmpty && borrows.isEmpty;

              if (allEmpty) {
                return Center(
                  child: Text(
                    'No lend/borrow entries yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              if (_selectedIndex == 0) {
                // All - combine both lists
                final all = <dynamic>[...lends, ...borrows]
                  ..sort((a, b) {
                    final aDate = a is Lend
                        ? a.lendDate
                        : (a as Borrow).borrowDate;
                    final bDate = b is Lend
                        ? b.lendDate
                        : (b as Borrow).borrowDate;
                    return bDate.compareTo(aDate);
                  });
                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: all.length,
                  itemBuilder: (_, index) =>
                      _buildEntryTile(controller, all[index]),
                );
              }

              if (_selectedIndex == 1) {
                final lendList = [...lends]
                  ..sort((a, b) => b.lendDate.compareTo(a.lendDate));

                if (lendList.isEmpty) {
                  return Center(
                    child: Text(
                      'No lend entries yet',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(AppConstants.defaultPadding),
                  itemCount: lendList.length,
                  itemBuilder: (_, index) =>
                      _buildEntryTile(controller, lendList[index]),
                );
              }

              final borrowList = [...borrows]
                ..sort((a, b) => b.borrowDate.compareTo(a.borrowDate));

              if (borrowList.isEmpty) {
                return Center(
                  child: Text(
                    'No borrow entries yet',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(AppConstants.defaultPadding),
                itemCount: borrowList.length,
                itemBuilder: (_, index) =>
                    _buildEntryTile(controller, borrowList[index]),
              );
            }),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Get.toNamed(AppRoutes.addLendBorrow),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEntryTile(LendBorrowController controller, dynamic entry) {
    final bool isLend;
    final String id;
    final String personName;
    final double amount;
    final String? note;
    final DateTime date;
    final bool settled;

    if (entry is Lend) {
      isLend = true;
      id = entry.id;
      personName = entry.personName;
      amount = entry.amount;
      note = entry.note;
      date = entry.lendDate;
      settled = entry.isSettled;
    } else {
      isLend = false;
      final borrowEntry = entry as Borrow;
      id = borrowEntry.id;
      personName = borrowEntry.personName;
      amount = borrowEntry.amount;
      note = borrowEntry.note;
      date = borrowEntry.borrowDate;
      settled = borrowEntry.isSettled;
    }

    final settledLabel = isLend ? 'Paid' : 'Returned';
    final avatarColor = settled
        ? Colors.grey.shade400
        : (isLend ? Colors.orange : Colors.blue);
    final type = isLend
        ? LendBorrowController.typeLend
        : LendBorrowController.typeBorrow;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => Get.toNamed(AppRoutes.addLendBorrow, arguments: entry),
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
                    controller.deleteEntry(id, type);
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
          contentPadding: const EdgeInsets.all(AppConstants.defaultPadding),
          leading: CircleAvatar(
            backgroundColor: avatarColor,
            child: Icon(
              isLend ? Icons.call_made_rounded : Icons.call_received_rounded,
              color: Colors.white,
            ),
          ),
          title: Text(
            personName,
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
              ),
              if (note != null && note.isNotEmpty)
                Text(
                  note,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              Text(
                DateHelper.formatDate(date),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                CurrencyHelper.formatAmount(amount),
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
                onTap: () => controller.toggleSettled(id, settled, type),
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
  }
}
