import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/expense_table.dart';
import 'tables/category_table.dart';
import 'tables/income_table.dart';
import 'tables/lend_borrow_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Expenses, Categories, Incomes, LendBorrows])
class AppDatabase extends _$AppDatabase {
  static const dbFileName = 'exptra.db';

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.createTable(lendBorrows);
      }
      if (from < 3) {
        await m.addColumn(lendBorrows, lendBorrows.isSettled);
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
