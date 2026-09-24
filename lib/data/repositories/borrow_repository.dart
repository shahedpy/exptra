import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../services/financial_calculator.dart';

import '../../core/db/app_database.dart';

class BorrowRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  BorrowRepository(this.db);

  Future<void> insertBorrow({
    required String personName,
    required double amount,
    String? accountId,
    String? note,
    required DateTime date,
  }) async {
    await db
        .into(db.borrows)
        .insert(
          BorrowsCompanion.insert(
            id: _uuid.v4(),
            personName: personName,
            amount: Money.normalize(amount),
            accountId: Value(accountId),
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

  Future<void> updateBorrow({
    required String id,
    required String personName,
    required double amount,
    String? accountId,
    String? note,
    required DateTime date,
  }) async {
    final repayments = await (db.select(
      db.borrowRepayments,
    )..where((r) => r.borrowId.equals(id) & r.isDeleted.equals(false))).get();
    final repaid = repayments.fold<int>(
      0,
      (sum, r) => sum + Money.cents(r.amount),
    );
    if (Money.cents(amount) <= 0 ||
        Money.cents(amount) < repaid ||
        repayments.any((r) => r.repaymentDate.isBefore(date))) {
      throw ArgumentError('Amount or date conflicts with recorded repayments');
    }
    await (db.update(db.borrows)..where((tbl) => tbl.id.equals(id))).write(
      BorrowsCompanion(
        personName: Value(personName),
        amount: Value(Money.normalize(amount)),
        accountId: Value(accountId),
        note: Value(note),
        borrowDate: Value(date),
      ),
    );
  }
}
