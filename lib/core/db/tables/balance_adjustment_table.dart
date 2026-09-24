import 'package:drift/drift.dart';
import 'account_table.dart';

class BalanceAdjustments extends Table {
  TextColumn get id => text()();
  TextColumn get accountId => text().references(Accounts, #id)();
  TextColumn get snapshotId => text().nullable()();
  DateTimeColumn get date => dateTime()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
