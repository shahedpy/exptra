import 'package:drift/drift.dart';
import 'account_table.dart';
import 'borrow_table.dart';

class BorrowRepayments extends Table {
  TextColumn get id => text()();
  TextColumn get borrowId => text().references(Borrows, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get repaymentDate => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
