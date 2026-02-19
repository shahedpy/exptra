import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'tables/expense_table.dart';
import 'tables/category_table.dart';
import 'tables/income_table.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Expenses, Categories, Incomes])
class AppDatabase extends _$AppDatabase {
  static const dbFileName = 'exptra.db';

  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

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
