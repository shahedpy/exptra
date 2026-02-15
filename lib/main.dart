import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'core/db/app_database.dart';
import 'core/theme/app_theme.dart';
import 'modules/dashboard/dashboard_page.dart';

void main() {
  final db = AppDatabase();
  Get.put<AppDatabase>(db);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Expense Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      home: const DashboardPage(),
    );
  }
}
