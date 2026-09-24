import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../services/financial_calculator.dart';

import '../../core/db/app_database.dart';

class LendRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  LendRepository(this.db);

  Future<void> insertLend({
    required String personName,
    required double amount,
    String? accountId,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.lends)
        .insert(
          LendsCompanion.insert(
            id: _uuid.v4(),
            personName: personName,
            amount: Money.normalize(amount),
            accountId: Value(accountId),
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

  Future<void> updateLend({
    required String id,
    required String personName,
    required double amount,
    String? accountId,
    String? note,
    required DateTime date,
  }) async {
    final repayments = await (db.select(
      db.lendRepayments,
    )..where((r) => r.lendId.equals(id) & r.isDeleted.equals(false))).get();
    final repaid = repayments.fold<int>(
      0,
      (sum, r) => sum + Money.cents(r.amount),
    );
    if (Money.cents(amount) <= 0 ||
        Money.cents(amount) < repaid ||
        repayments.any((r) => r.repaymentDate.isBefore(date))) {
      throw ArgumentError('Amount or date conflicts with recorded repayments');
    }
    await (db.update(db.lends)..where((tbl) => tbl.id.equals(id))).write(
      LendsCompanion(
        personName: Value(personName),
        amount: Value(Money.normalize(amount)),
        accountId: Value(accountId),
        note: Value(note),
        lendDate: Value(date),
      ),
    );
  }
}
