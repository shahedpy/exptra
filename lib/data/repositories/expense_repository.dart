import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/app_database.dart';

class ExpenseRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  ExpenseRepository(this.db);

  Future<void> insertExpense({
    required String categoryId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.expenses)
        .insert(
          ExpensesCompanion.insert(
            id: _uuid.v4(),
            categoryId: categoryId,
            amount: amount,
            note: Value(note),
            expenseDate: date,
          ),
        );
  }

  Future<List<Expense>> getAllExpenses() {
    return (db.select(db.expenses)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.expenseDate)]))
        .get();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.expenses)..where((tbl) => tbl.id.equals(id))).write(
      ExpensesCompanion(isDeleted: const Value(true)),
    );
  }

  Future<void> updateExpense({
    required String id,
    required String categoryId,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await (db.update(db.expenses)..where((tbl) => tbl.id.equals(id))).write(
      ExpensesCompanion(
        categoryId: Value(categoryId),
        amount: Value(amount),
        note: Value(note),
        expenseDate: Value(date),
      ),
    );
  }
}
