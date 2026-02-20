import 'package:drift/drift.dart';

class ExpenseCategories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  IntColumn get color => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}
