import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../../core/db/app_database.dart';

class BankRepository {
  final AppDatabase db;
  final _uuid = const Uuid();

  BankRepository(this.db);

  Future<List<Bank>> getAllBanks() {
    return (db.select(db.banks)
          ..where((table) => table.isDeleted.equals(false))
          ..orderBy([
            (table) => OrderingTerm.asc(table.sortOrder),
            (table) => OrderingTerm.asc(table.name),
          ]))
        .get();
  }

  Future<void> insertBank({required String name}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Bank name is required');
    }
    await _ensureNameIsAvailable(normalizedName);

    final maxSortOrderExpr = db.banks.sortOrder.max();
    final maxSortOrder =
        await (db.selectOnly(db.banks)..addColumns([maxSortOrderExpr]))
            .map((row) => row.read(maxSortOrderExpr))
            .getSingle();

    await db
        .into(db.banks)
        .insert(
          BanksCompanion.insert(
            id: _uuid.v4(),
            name: normalizedName,
            sortOrder: Value((maxSortOrder ?? -1) + 1),
          ),
        );
  }

  Future<void> updateBank({required String id, required String name}) async {
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw ArgumentError('Bank name is required');
    }
    final bank = await (db.select(
      db.banks,
    )..where((table) => table.id.equals(id))).getSingle();
    await _ensureNameIsAvailable(normalizedName, excludingId: id);

    await db.transaction(() async {
      await (db.update(db.banks)..where((table) => table.id.equals(id))).write(
        BanksCompanion(name: Value(normalizedName)),
      );
      if (bank.name != normalizedName) {
        await (db.update(db.accounts)
              ..where((account) => account.institutionName.equals(bank.name)))
            .write(AccountsCompanion(institutionName: Value(normalizedName)));
      }
    });
  }

  Future<int> getAccountCountByBank(String name) {
    return (db.selectOnly(db.accounts)
          ..addColumns([countAll()])
          ..where(
            db.accounts.institutionName.equals(name) &
                db.accounts.isDeleted.equals(false),
          ))
        .map((row) => row.read(countAll()) ?? 0)
        .getSingle();
  }

  Future<void> softDelete(String id) {
    return (db.update(db.banks)..where((table) => table.id.equals(id))).write(
      const BanksCompanion(isDeleted: Value(true)),
    );
  }

  Future<void> reorderBanks(List<String> orderedIds) async {
    await db.transaction(() async {
      for (var index = 0; index < orderedIds.length; index++) {
        await (db.update(db.banks)
              ..where((table) => table.id.equals(orderedIds[index])))
            .write(BanksCompanion(sortOrder: Value(index)));
      }
    });
  }

  Future<void> _ensureNameIsAvailable(
    String name, {
    String? excludingId,
  }) async {
    final banks = await getAllBanks();
    final duplicate = banks.any(
      (bank) =>
          bank.id != excludingId &&
          bank.name.toLowerCase() == name.toLowerCase(),
    );
    if (duplicate) {
      throw StateError('A bank with this name already exists');
    }
  }
}
