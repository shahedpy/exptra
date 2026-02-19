import 'package:drift/drift.dart';

class Incomes extends Table {
  TextColumn get id => text()();
  RealColumn get amount => real()();
  TextColumn get source => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get incomeDate => dateTime()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
