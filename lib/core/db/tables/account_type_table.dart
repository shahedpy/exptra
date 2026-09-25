import 'package:drift/drift.dart';

class AccountTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get classification => text()();
  BoolColumn get requiresInstitution =>
      boolean().withDefault(const Constant(false))();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
