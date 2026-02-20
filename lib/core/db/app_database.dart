import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/expense_table.dart';
import 'tables/category_table.dart';
import 'tables/income_table.dart';
import 'tables/lend_table.dart';
import 'tables/borrow_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Expenses, Categories, Incomes, Lends, Borrows])
class AppDatabase extends _$AppDatabase {
  static const dbFileName = 'exptra.db';

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 4) {
        // Create new tables
        await m.createTable(lends);
        await m.createTable(borrows);

        // Migrate data from old LendBorrows table if it exists (from schema v2 or v3)
        try {
          final existingData = await customSelect(
            'SELECT * FROM lend_borrows WHERE is_deleted = 0',
          ).get();

          for (final row in existingData) {
            final type = row.read<String>('type');
            final id = row.read<String>('id');
            final personName = row.read<String>('person_name');
            final amount = row.read<double>('amount');
            final note = row.readNullable<String>('note');
            final transactionDate = row.read<DateTime>('transaction_date');
            final isSettled = row.read<bool>('is_settled');
            final isDeleted = row.read<bool>('is_deleted');
            final createdAt = row.read<DateTime>('created_at');

            if (type.toLowerCase() == 'lend') {
              await into(lends).insert(
                LendsCompanion.insert(
                  id: id,
                  personName: personName,
                  amount: amount,
                  note: Value(note),
                  lendDate: transactionDate,
                  isSettled: Value(isSettled),
                  isDeleted: Value(isDeleted),
                  createdAt: Value(createdAt),
                ),
              );
            } else if (type.toLowerCase() == 'borrow') {
              await into(borrows).insert(
                BorrowsCompanion.insert(
                  id: id,
                  personName: personName,
                  amount: amount,
                  note: Value(note),
                  borrowDate: transactionDate,
                  isSettled: Value(isSettled),
                  isDeleted: Value(isDeleted),
                  createdAt: Value(createdAt),
                ),
              );
            }
          }

          // Drop old table
          await customStatement('DROP TABLE IF EXISTS lend_borrows');
        } catch (e) {
          // Table might not exist if upgrading from schema v1 directly
          // Just create the new tables without migration
        }
      }
    },
  );

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
