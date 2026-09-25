import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/expense_table.dart';
import 'tables/expense_category_table.dart';
import 'tables/income_table.dart';
import 'tables/income_source_table.dart';
import 'tables/lend_table.dart';
import 'tables/borrow_table.dart';

import 'tables/account_table.dart';
import 'tables/account_transfer_table.dart';
import 'tables/account_balance_snapshot_table.dart';
import 'tables/balance_adjustment_table.dart';
import 'tables/lend_repayment_table.dart';
import 'tables/borrow_repayment_table.dart';
import 'tables/bank_table.dart';
import 'tables/account_type_table.dart';
import '../../data/models/account_type_defaults.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Expenses,
    ExpenseCategories,
    Incomes,
    IncomeSources,
    Lends,
    Borrows,
    Accounts,
    AccountTransfers,
    AccountBalanceSnapshots,
    BalanceAdjustments,
    LendRepayments,
    BorrowRepayments,
    Banks,
    AccountTypes,
  ],
)
class AppDatabase extends _$AppDatabase {
  static const dbFileName = 'exptra.db';

  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedAccountTypes();
      await _createIndexes();
      await customStatement(
        'CREATE UNIQUE INDEX IF NOT EXISTS idx_account_types_active_name ON account_types (lower(name)) WHERE is_deleted = 0',
      );
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(accounts);
        await m.addColumn(incomes, incomes.accountId);
        await m.addColumn(expenses, expenses.accountId);
        await m.addColumn(lends, lends.accountId);
        await m.addColumn(borrows, borrows.accountId);
        await m.createTable(accountTransfers);
        await m.createTable(accountBalanceSnapshots);
        await m.createTable(balanceAdjustments);
        await m.createTable(lendRepayments);
        await m.createTable(borrowRepayments);
        await _createIndexes();
      }
      if (from < 3) {
        await m.createTable(banks);
        await customStatement('''
          INSERT INTO banks (id, name, sort_order, is_deleted)
          SELECT 'legacy-bank-' || MIN(rowid), institution_name, 0, 0
          FROM accounts
          WHERE trim(institution_name) <> ''
          GROUP BY institution_name
        ''');
      }
      if (from < 4) {
        await m.createTable(accountTypes);
        // Upgrades from v1 created the current accounts table above.
        if (from >= 2) {
          await m.addColumn(accounts, accounts.accountTypeId);
        }
        await _seedAccountTypes();
        // Preserve every unknown legacy label as its own managed type.
        await customStatement('''
          INSERT INTO account_types (id, name, classification, requires_institution, sort_order, is_system, is_deleted, created_at)
          SELECT 'legacy-type-' || MIN(rowid), trim(type), 'liquid', 0, 1000 + MIN(rowid), 0, 0, CAST(strftime('%s', 'now') AS INTEGER)
          FROM accounts
          WHERE trim(type) <> ''
            AND NOT EXISTS (SELECT 1 FROM account_types WHERE lower(name) = lower(trim(accounts.type)))
          GROUP BY lower(trim(type))
        ''');
        await customStatement('''
          UPDATE accounts SET account_type_id =
            (SELECT id FROM account_types WHERE lower(name) = lower(trim(accounts.type)) LIMIT 1)
        ''');
        await customStatement(
          "UPDATE accounts SET account_type_id = 'system-other' WHERE account_type_id IS NULL",
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS idx_account_types_active_name ON account_types (lower(name)) WHERE is_deleted = 0',
        );
      }
    },
  );

  Future<void> _createIndexes() async {
    for (final sql in [
      'CREATE INDEX IF NOT EXISTS idx_income_account_date ON incomes (account_id, income_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_expense_account_date ON expenses (account_id, expense_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_lend_account_date ON lends (account_id, lend_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_borrow_account_date ON borrows (account_id, borrow_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_lend_person ON lends (person_name, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_borrow_person ON borrows (person_name, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_transfer_from_date ON account_transfers (from_account_id, transfer_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_transfer_to_date ON account_transfers (to_account_id, transfer_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_snapshot_account_date ON account_balance_snapshots (account_id, date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_adjustment_account_date ON balance_adjustments (account_id, date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_lend_repayment_date ON lend_repayments (lend_id, account_id, repayment_date, is_deleted)',
      'CREATE INDEX IF NOT EXISTS idx_borrow_repayment_date ON borrow_repayments (borrow_id, account_id, repayment_date, is_deleted)',
    ]) {
      await customStatement(sql);
    }
  }

  Future<void> _seedAccountTypes() async {
    for (var i = 0; i < defaultAccountTypes.length; i++) {
      final type = defaultAccountTypes[i];
      await customStatement(
        '''
        INSERT OR IGNORE INTO account_types
          (id, name, classification, requires_institution, sort_order, is_system, is_deleted, created_at)
        VALUES (?, ?, ?, ?, ?, 1, 0, CAST(strftime('%s', 'now') AS INTEGER))
      ''',
        [
          type.id,
          type.name,
          type.classification,
          type.requiresInstitution ? 1 : 0,
          i,
        ],
      );
    }
  }

  static Future<String> dbFilePath() async {
    final directory = await getApplicationDocumentsDirectory();
    return p.join(directory.path, dbFileName);
  }
}

QueryExecutor _openConnection() {
  return driftDatabase(
    name: AppDatabase.dbFileName,
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationDocumentsDirectory,
    ),
  );
}
