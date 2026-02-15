import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../expense/expense_controller.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ExpenseController());

    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard")),
      body: Obx(() {
        return ListView.builder(
          itemCount: controller.expenses.length,
          itemBuilder: (_, index) {
            final expense = controller.expenses[index];
            return ListTile(
              title: Text(expense.amount.toString()),
              subtitle: Text(expense.expenseDate.toString()),
            );
          },
        );
      }),
    );
  }
}
