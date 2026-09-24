import 'package:drift/drift.dart';
import 'account_table.dart';
import 'lend_table.dart';

class LendRepayments extends Table {
  TextColumn get id => text()();
  TextColumn get lendId => text().references(Lends, #id)();
  TextColumn get accountId => text().nullable().references(Accounts, #id)();
  RealColumn get amount => real()();
  DateTimeColumn get repaymentDate => dateTime()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
