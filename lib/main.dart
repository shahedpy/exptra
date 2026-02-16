import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/db/app_database.dart';
import 'core/theme/app_theme.dart';
import 'core/routes/app_routes.dart';
import 'modules/expense/expense_controller.dart';
import 'modules/category/category_controller.dart';

void main() {
  final db = AppDatabase();
  Get.put<AppDatabase>(db);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize controllers
    Get.put(ExpenseController());
    Get.put(CategoryController());

    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      getPages: AppRoutes.routes,
      initialRoute: AppRoutes.dashboard,
    );
  }
}


