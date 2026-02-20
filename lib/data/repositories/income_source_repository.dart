import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class IncomeSourceRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  IncomeSourceRepository(this.db);

  Future<void> insertIncomeSource({
    required String name,
    required int color,
  }) async {
    await db
        .into(db.incomeSources)
        .insert(
          IncomeSourcesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            color: Value(color),
          ),
        );
  }

  Future<List<IncomeSource>> getAllIncomeSources() {
    return (db.select(db.incomeSources)
          ..where((tbl) => tbl.isDeleted.equals(false))
          ..orderBy([(t) => OrderingTerm.asc(t.name)]))
        .get();
  }

  Future<void> updateIncomeSource({
    required String id,
    required String name,
    required int color,
  }) {
    return (db.update(db.incomeSources)..where((tbl) => tbl.id.equals(id)))
        .write(IncomeSourcesCompanion(name: Value(name), color: Value(color)));
  }

  Future<void> softDelete(String id) {
    return (db.update(db.incomeSources)..where((tbl) => tbl.id.equals(id)))
        .write(const IncomeSourcesCompanion(isDeleted: Value(true)));
  }

  Future<int> getIncomeCountBySource(String sourceId) {
    return (db.selectOnly(db.incomes)
          ..addColumns([countAll()])
          ..where(
            db.incomes.sourceId.equals(sourceId) &
                db.incomes.isDeleted.equals(false),
          ))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
  }
}
