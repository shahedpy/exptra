import 'package:drift/drift.dart';
import 'account_table.dart';

class AccountTransfers extends Table {
  TextColumn get id => text()();
  @ReferenceName('outgoingTransfers')
  TextColumn get fromAccountId => text().references(Accounts, #id)();
  @ReferenceName('incomingTransfers')
  TextColumn get toAccountId => text().references(Accounts, #id)();
  RealColumn get amount => real()();
  RealColumn get fee => real().withDefault(const Constant(0))();
  TextColumn get note => text().nullable()();
  DateTimeColumn get transferDate => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
