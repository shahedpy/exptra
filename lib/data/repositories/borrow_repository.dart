import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class BorrowRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  BorrowRepository(this.db);

  Future<void> insertBorrow({
    required String personName,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.borrows)
        .insert(
          BorrowsCompanion.insert(
            id: _uuid.v4(),
            personName: personName,
            amount: amount,
            note: Value(note),
            borrowDate: date,
          ),
        );
  }

  Future<List<Borrow>> getAllBorrows() {
    return (db.select(db.borrows)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.borrowDate)]))
        .get();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.borrows)..where((tbl) => tbl.id.equals(id))).write(
      BorrowsCompanion(isDeleted: const Value(true)),
    );
  }

  Future<void> toggleSettled(String id, bool value) {
    return (db.update(db.borrows)..where((tbl) => tbl.id.equals(id))).write(
      BorrowsCompanion(isSettled: Value(value)),
    );
  }

  Future<void> updateBorrow({
    required String id,
    required String personName,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await (db.update(db.borrows)..where((tbl) => tbl.id.equals(id))).write(
      BorrowsCompanion(
        personName: Value(personName),
        amount: Value(amount),
        note: Value(note),
        borrowDate: Value(date),
      ),
    );
  }
}
