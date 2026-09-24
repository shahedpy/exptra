import 'account_table.dart';
import 'package:drift/drift.dart';
import 'expense_category_table.dart';

class Expenses extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(ExpenseCategories, #id)();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get expenseDate => dateTime()();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
