import 'package:drift/drift.dart';
import 'account_type_table.dart';

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get institutionName => text().withDefault(const Constant(''))();
  TextColumn get name => text()();
  TextColumn get type => text()();
  TextColumn get accountTypeId =>
      text().nullable().references(AccountTypes, #id)();
  TextColumn get currency => text().withDefault(const Constant('BDT'))();
  RealColumn get openingBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get openingBalanceDate => dateTime()();
  TextColumn get note => text().nullable()();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get includeInNetWorth =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
