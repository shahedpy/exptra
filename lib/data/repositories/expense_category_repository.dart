import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/app_database.dart';

class ExpenseCategoryRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  ExpenseCategoryRepository(this.db);

  Future<void> insertCategory({
    required String name,
    required int color,
  }) async {
    await db
        .into(db.expenseCategories)
        .insert(
          ExpenseCategoriesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            color: Value(color),
          ),
        );
  }

  Future<List<ExpenseCategory>> getAllCategories() {
    return (db.select(db.expenseCategories)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<ExpenseCategory?> getCategoryById(String id) {
    return (db.select(db.expenseCategories)
          ..where((tbl) => tbl.id.equals(id) & tbl.isDeleted.equals(false)))
        .getSingleOrNull();
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required int color,
  }) {
    return (db.update(
      db.expenseCategories,
    )..where((tbl) => tbl.id.equals(id))).write(
      ExpenseCategoriesCompanion(name: Value(name), color: Value(color)),
    );
  }

  Future<void> softDelete(String id) {
    return (db.update(db.expenseCategories)..where((tbl) => tbl.id.equals(id)))
        .write(const ExpenseCategoriesCompanion(isDeleted: Value(true)));
  }

  Future<int> getExpenseCountByCategory(String categoryId) {
    return (db.selectOnly(db.expenses)
          ..addColumns([countAll()])
          ..where(
            db.expenses.categoryId.equals(categoryId) &
                db.expenses.isDeleted.equals(false),
          ))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
  }
}
