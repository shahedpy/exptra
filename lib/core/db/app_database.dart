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
  ],
)
class AppDatabase extends _$AppDatabase {
  static const dbFileName = 'exptra.db';

  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _createIndexes();
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
