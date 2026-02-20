import 'package:get/get.dart';
import '../../modules/expense/add_expense_page.dart';
import '../../modules/income/add_income_page.dart';
import '../../modules/category/category_page.dart';
import '../../modules/lend_borrow/add_lend_borrow_page.dart';
import '../../modules/lend_borrow/lend_borrow_page.dart';
import '../../modules/navigation/main_navigation_page.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String lendBorrow = '/lend-borrow';
  static const String addLendBorrow = '/add-lend-borrow';
  static const String categories = '/categories';

  static final routes = [
    GetPage(name: dashboard, page: () => const MainNavigationPage()),
    GetPage(name: addExpense, page: () => const AddExpensePage()),
    GetPage(name: addIncome, page: () => const AddIncomePage()),
    GetPage(name: lendBorrow, page: () => const LendBorrowPage()),
    GetPage(name: addLendBorrow, page: () => const AddLendBorrowPage()),
    GetPage(name: categories, page: () => CategoryPage()),
  ];
}
