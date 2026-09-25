import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/app_database.dart';
import '../models/account_type_defaults.dart';

class AccountTypeRepository {
  final AppDatabase db;
  static const _uuid = Uuid();
  AccountTypeRepository(this.db);

  Future<List<AccountType>> all({bool includeDeleted = false}) =>
      (db.select(db.accountTypes)
            ..where(
              (t) => includeDeleted
                  ? const Constant(true)
                  : t.isDeleted.equals(false),
            )
            ..orderBy([
              (t) => OrderingTerm.asc(t.sortOrder),
              (t) => OrderingTerm.asc(t.name),
            ]))
          .get();

  Future<void> seedDefaultsIfEmpty() async {
    if ((await all(includeDeleted: true)).isNotEmpty) return;
    for (var i = 0; i < defaultAccountTypes.length; i++) {
      final type = defaultAccountTypes[i];
      await db
          .into(db.accountTypes)
          .insert(
            AccountTypesCompanion.insert(
              id: type.id,
              name: type.name,
              classification: type.classification,
              requiresInstitution: Value(type.requiresInstitution),
              sortOrder: Value(i),
              isSystem: const Value(true),
            ),
          );
    }
  }

  Future<AccountType> create({
    required String name,
    required String classification,
    required bool requiresInstitution,
  }) async {
    final clean = name.trim();
    await _validate(clean, classification);
    final rows = await all(includeDeleted: true);
    final nextOrder =
        rows.fold<int>(
          -1,
          (order, t) => t.sortOrder > order ? t.sortOrder : order,
        ) +
        1;
    final id = _uuid.v4();
    await db
        .into(db.accountTypes)
        .insert(
          AccountTypesCompanion.insert(
            id: id,
            name: clean,
            classification: classification,
            requiresInstitution: Value(requiresInstitution),
            sortOrder: Value(nextOrder),
          ),
        );
    return (db.select(
      db.accountTypes,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<AccountType> update({
    required String id,
    required String name,
    required String classification,
    required bool requiresInstitution,
  }) async {
    final clean = name.trim();
    await _validate(clean, classification, excludingId: id);
    await db.transaction(() async {
      await (db.update(db.accountTypes)..where((t) => t.id.equals(id))).write(
        AccountTypesCompanion(
          name: Value(clean),
          classification: Value(classification),
          requiresInstitution: Value(requiresInstitution),
        ),
      );
      // The ID remains authoritative. Keep the legacy label in sync for older views and exports.
      await (db.update(db.accounts)..where((a) => a.accountTypeId.equals(id)))
          .write(AccountsCompanion(type: Value(clean)));
    });
    return (db.select(
      db.accountTypes,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<bool> deleteIfUnused(String id) async {
    final references =
        await (db.select(db.accounts)..where(
              (a) => a.accountTypeId.equals(id) & a.isDeleted.equals(false),
            ))
            .get();
    if (references.isNotEmpty) return false;
    await (db.update(db.accountTypes)..where((t) => t.id.equals(id))).write(
      const AccountTypesCompanion(isDeleted: Value(true)),
    );
    return true;
  }

  Future<void> reorder(List<String> orderedIds) async {
    await db.transaction(() async {
      for (var i = 0; i < orderedIds.length; i++) {
        await (db.update(db.accountTypes)
              ..where((t) => t.id.equals(orderedIds[i])))
            .write(AccountTypesCompanion(sortOrder: Value(i)));
      }
    });
  }

  Future<AccountType> resolveLegacy(String name) async {
    final clean = name.trim().isEmpty ? 'Other' : name.trim();
    final rows = await all();
    for (final type in rows) {
      if (type.name.toLowerCase() == clean.toLowerCase()) return type;
    }
    return create(
      name: clean,
      classification: AccountTypeClass.liquid,
      requiresInstitution: false,
    );
  }

  Future<void> _validate(
    String name,
    String classification, {
    String? excludingId,
  }) async {
    if (name.isEmpty) throw ArgumentError('Account type name is required');
    if (!AccountTypeClass.values.contains(classification)) {
      throw ArgumentError('Choose a financial group');
    }
    final rows = await all();
    if (rows.any(
      (t) => t.id != excludingId && t.name.toLowerCase() == name.toLowerCase(),
    )) {
      throw StateError('An account type with this name already exists');
    }
  }
}
