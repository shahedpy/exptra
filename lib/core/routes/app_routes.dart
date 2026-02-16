import 'package:get/get.dart';
import '../../modules/dashboard/dashboard_page.dart';
import '../../modules/expense/add_expense_page.dart';
import '../../modules/category/category_page.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String addExpense = '/add-expense';
  static const String categories = '/categories';

  static final routes = [
    GetPage(
      name: dashboard,
      page: () => const DashboardPage(),
    ),
    GetPage(
      name: addExpense,
      page: () => const AddExpensePage(),
    ),
    GetPage(
      name: categories,
      page: () => CategoryPage(),
    ),
  ];
}

