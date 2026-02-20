import 'package:drift/drift.dart';

class Borrows extends Table {
  TextColumn get id => text()();
  TextColumn get personName => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get borrowDate => dateTime()();
  BoolColumn get isSettled => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
