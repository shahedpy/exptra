import 'package:drift/drift.dart';
import 'account_table.dart';

class AccountBalanceSnapshots extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  DateTimeColumn get date => dateTime()();
  RealColumn get actualBalance => real()();
  RealColumn get calculatedBalance => real()();
  RealColumn get difference => real()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
