import 'package:get/get.dart';
import '../../modules/income_expense/add_expense_page.dart';
import '../../modules/income_expense/add_income_page.dart';
import '../../modules/expense_category/expense_category_page.dart';
import '../../modules/income_source/income_source_page.dart';
import '../../modules/lend_borrow/add_borrow_page.dart';
import '../../modules/lend_borrow/add_lend_page.dart';
import '../../modules/lend_borrow/lend_borrow_page.dart';
import '../../modules/navigation/main_navigation_page.dart';

class AppRoutes {
  static const String dashboard = '/';
  static const String addExpense = '/add-expense';
  static const String addIncome = '/add-income';
  static const String lendBorrow = '/lend-borrow';
  static const String addLend = '/add-lend';
  static const String addBorrow = '/add-borrow';
  static const String expenseCategories = '/categories';
  static const String incomeSources = '/income-sources';

  static final routes = [
    GetPage(name: dashboard, page: () => const MainNavigationPage()),
    GetPage(name: addExpense, page: () => const AddExpensePage()),
    GetPage(name: addIncome, page: () => const AddIncomePage()),
    GetPage(name: lendBorrow, page: () => const LendBorrowPage()),
    GetPage(name: addLend, page: () => const AddLendPage()),
    GetPage(name: addBorrow, page: () => const AddBorrowPage()),
    GetPage(name: expenseCategories, page: () => const ExpenseCategoryPage()),
    GetPage(name: incomeSources, page: () => const IncomeSourcePage()),
  ];
}
