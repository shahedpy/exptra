import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class LendRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  LendRepository(this.db);

  Future<void> insertLend({
    required String personName,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.lends)
        .insert(
          LendsCompanion.insert(
            id: _uuid.v4(),
            personName: personName,
            amount: amount,
            note: Value(note),
            lendDate: date,
          ),
        );
  }

  Future<List<Lend>> getAllLends() {
    return (db.select(db.lends)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.desc(t.lendDate)]))
        .get();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.lends)..where((tbl) => tbl.id.equals(id))).write(
      LendsCompanion(isDeleted: const Value(true)),
    );
  }

  Future<void> toggleSettled(String id, bool value) {
    return (db.update(db.lends)..where((tbl) => tbl.id.equals(id))).write(
      LendsCompanion(isSettled: Value(value)),
    );
  }

  Future<void> updateLend({
    required String id,
    required String personName,
    required double amount,
    String? note,
    required DateTime date,
  }) async {
    await (db.update(db.lends)..where((tbl) => tbl.id.equals(id))).write(
      LendsCompanion(
        personName: Value(personName),
        amount: Value(amount),
        note: Value(note),
        lendDate: Value(date),
      ),
    );
  }
}
