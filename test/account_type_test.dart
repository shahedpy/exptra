import 'dart:convert';
import 'dart:io';
import 'package:drift/native.dart';
import 'package:exptra/core/db/app_database.dart';
import 'package:exptra/core/db/database_backup_service.dart';
import 'package:exptra/data/models/account_type_defaults.dart';
import 'package:exptra/data/repositories/account_type_repository.dart';
import 'package:exptra/data/repositories/accounting_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late AccountTypeRepository types;
  late AccountingRepository accounting;
  final day = DateTime(2026, 9, 24);
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    types = AccountTypeRepository(db);
    accounting = AccountingRepository(db);
  });
  tearDown(() async => db.close());

  test('defaults have financial groups and institution rules', () async {
    final rows = await types.all();
    expect(
      rows.map((t) => t.name).toList(),
      defaultAccountTypes.map((t) => t.name).toList(),
    );
    expect(
      rows.firstWhere((t) => t.name == 'Savings').requiresInstitution,
      true,
    );
    expect(rows.firstWhere((t) => t.name == 'Cash').requiresInstitution, false);
    expect(
      rows.firstWhere((t) => t.name == 'FDR').classification,
      AccountTypeClass.investment,
    );
  });

  test('custom groups drive balances and survive rename', () async {
    final investment = await types.create(
      name: 'Provident Fund',
      classification: AccountTypeClass.investment,
      requiresInstitution: false,
    );
    final liquid = await types.create(
      name: 'Wallet',
      classification: AccountTypeClass.liquid,
      requiresInstitution: false,
    );
    final other = await types.create(
      name: 'Collectible',
      classification: AccountTypeClass.other,
      requiresInstitution: false,
    );
    for (final (type, amount) in [
      (investment, 1000.0),
      (liquid, 200.0),
      (other, 50.0),
    ]) {
      await accounting.saveAccount(
        institutionName: '',
        name: type.name,
        type: type.name,
        accountTypeId: type.id,
        openingBalance: amount,
        openingBalanceDate: day,
      );
    }
    var position = (await accounting.calculator()).position();
    expect(position.investments, 100000);
    expect(position.bankAndCash, 20000);
    expect(position.otherAssets, 5000);
    expect(position.netWorth, 125000);
    expect(await types.deleteIfUnused(investment.id), false);
    final unused = await types.create(
      name: 'Temporary',
      classification: AccountTypeClass.other,
      requiresInstitution: false,
    );
    expect(await types.deleteIfUnused(unused.id), true);
    expect((await types.all()).any((t) => t.id == unused.id), false);
    await accounting.saveAccount(
      institutionName: '',
      name: 'Excluded',
      type: other.name,
      accountTypeId: other.id,
      openingBalance: 70,
      openingBalanceDate: day,
      includeInNetWorth: false,
    );
    position = (await accounting.calculator()).position();
    expect(position.excludedAssets, 7000);
    expect(position.netWorth, 125000);

    await types.update(
      id: investment.id,
      name: 'Retirement Fund',
      classification: AccountTypeClass.investment,
      requiresInstitution: false,
    );
    final account = (await accounting.accounts()).firstWhere(
      (a) => a.accountTypeId == investment.id,
    );
    expect(account.type, 'Retirement Fund');
    position = (await accounting.calculator()).position();
    expect(position.investments, 100000);
    expect(position.netWorth, 125000);
    await expectLater(
      types.create(
        name: ' retirement fund ',
        classification: AccountTypeClass.other,
        requiresInstitution: false,
      ),
      throwsStateError,
    );
  });

  test(
    'backup preserves managed types and old backups map legacy names',
    () async {
      final custom = await types.create(
        name: 'Fixed Deposit',
        classification: AccountTypeClass.investment,
        requiresInstitution: false,
      );
      await accounting.saveAccount(
        institutionName: '',
        name: 'Deposit',
        type: custom.name,
        accountTypeId: custom.id,
        openingBalance: 300,
        openingBalanceDate: day,
      );
      final temp = await Directory.systemTemp.createTemp('exptra-types-');
      try {
        final service = DatabaseBackupService();
        final current = await service.createBackupFile(
          db,
          outputPath: '${temp.path}/current.exptra',
        );
        final payload =
            jsonDecode(await current.readAsString()) as Map<String, dynamic>;
        expect(payload['version'], 4);
        expect(
          (payload['accountTypes'] as List).any((t) => t['id'] == custom.id),
          true,
        );
        await service.restoreBackupFromPath(
          backupPath: current.path,
          database: db,
        );
        expect((await accounting.calculator()).position().investments, 30000);
        expect((await accounting.accounts()).single.accountTypeId, custom.id);

        for (final version in [2, 3]) {
          final old = Map<String, dynamic>.from(payload)
            ..remove('accountTypes');
          old['version'] = version;
          final oldAccounts = (old['accounts'] as List)
              .map(
                (a) =>
                    Map<String, dynamic>.from(a as Map)
                      ..remove('accountTypeId'),
              )
              .toList();
          old['accounts'] = oldAccounts;
          final legacyFile = File('${temp.path}/legacy-$version.exptra');
          await legacyFile.writeAsString(jsonEncode(old));
          await service.restoreBackupFromPath(
            backupPath: legacyFile.path,
            database: db,
          );
          final restored = (await accounting.accounts()).single;
          expect(restored.type, 'Fixed Deposit');
          expect(restored.accountTypeId, isNotNull);
          expect(
            (await types.all()).any(
              (t) =>
                  t.id == restored.accountTypeId &&
                  t.name == 'Fixed Deposit' &&
                  t.classification == AccountTypeClass.liquid,
            ),
            true,
          );
        }
      } finally {
        await temp.delete(recursive: true);
      }
    },
  );

  test('version 3 accounts migrate without losing unknown type names', () async {
    await db.close();
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute('''CREATE TABLE accounts (
        id TEXT NOT NULL PRIMARY KEY, institution_name TEXT NOT NULL DEFAULT '', name TEXT NOT NULL,
        type TEXT NOT NULL, currency TEXT NOT NULL DEFAULT 'BDT', opening_balance REAL NOT NULL DEFAULT 0,
        opening_balance_date INTEGER NOT NULL, note TEXT, sort_order INTEGER NOT NULL DEFAULT 0,
        include_in_net_worth INTEGER NOT NULL DEFAULT 1, is_archived INTEGER NOT NULL DEFAULT 0,
        is_deleted INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime('%s', 'now'))
      )''');
          raw.execute(
            "INSERT INTO accounts (id, name, type, opening_balance, opening_balance_date) VALUES ('known', 'Savings', 'Savings', 100, 1788739200)",
          );
          raw.execute(
            "INSERT INTO accounts (id, name, type, opening_balance, opening_balance_date) VALUES ('unknown', 'Fund', 'Provident Fund', 200, 1788739200)",
          );
          raw.execute('PRAGMA user_version = 3');
        },
      ),
    );
    types = AccountTypeRepository(db);
    final accounts = await db.select(db.accounts).get();
    expect(accounts.length, 2);
    expect(
      accounts.firstWhere((a) => a.id == 'known').accountTypeId,
      'system-savings',
    );
    final unknown = accounts.firstWhere((a) => a.id == 'unknown');
    expect(unknown.type, 'Provident Fund');
    expect(
      (await types.all()).firstWhere((t) => t.id == unknown.accountTypeId).name,
      'Provident Fund',
    );
    expect(
      (await types.all())
          .firstWhere((t) => t.id == unknown.accountTypeId)
          .classification,
      AccountTypeClass.liquid,
    );
  });
}
