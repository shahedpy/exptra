import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class IncomeRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  IncomeRepository(this.db);

  Future<void> insertIncome({
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.incomes)
        .insert(
          IncomesCompanion.insert(
            id: _uuid.v4(),
            amount: amount,
            note: Value(note),
            incomeDate: date,
          ),
        );
  }

  Future<List<Income>> getAllIncomes() {
    return (db.select(db.incomes)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.incomeDate)]))
        .get();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.incomes)..where((tbl) => tbl.id.equals(id))).write(
      IncomesCompanion(isDeleted: const Value(true)),
    );
  }
}
