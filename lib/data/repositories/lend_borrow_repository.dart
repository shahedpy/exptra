import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class LendBorrowRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  LendBorrowRepository(this.db);

  Future<void> insertLendBorrow({
    required String personName,
    required double amount,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.lendBorrows)
        .insert(
          LendBorrowsCompanion.insert(
            id: _uuid.v4(),
            personName: personName,
            amount: amount,
            type: type,
            note: Value(note),
            transactionDate: date,
          ),
        );
  }

  Future<List<LendBorrow>> getAllEntries() {
    return (db.select(db.lendBorrows)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.transactionDate)]))
        .get();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.lendBorrows)..where((tbl) => tbl.id.equals(id))).write(
      LendBorrowsCompanion(isDeleted: const Value(true)),
    );
  }

  Future<void> toggleSettled(String id, bool value) {
    return (db.update(db.lendBorrows)..where((tbl) => tbl.id.equals(id))).write(
      LendBorrowsCompanion(isSettled: Value(value)),
    );
  }

  Future<void> updateLendBorrow({
    required String id,
    required String personName,
    required double amount,
    required String type,
    String? note,
    required DateTime date,
  }) async {
    await (db.update(db.lendBorrows)..where((tbl) => tbl.id.equals(id))).write(
      LendBorrowsCompanion(
        personName: Value(personName),
        amount: Value(amount),
        type: Value(type),
        note: Value(note),
        transactionDate: Value(date),
      ),
    );
  }
}
