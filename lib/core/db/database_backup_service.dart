import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

class DatabaseBackupService {
  Future<File> createBackupFile(AppDatabase database) async {
    final categories = await database.select(database.categories).get();
    final expenses = await database.select(database.expenses).get();
    final incomes = await database.select(database.incomes).get();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(tempDir.path, 'exptra-backup-$timestamp.exptra');

    final backupPayload = {
      'version': 2,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories
          .map(
            (category) => {
              'id': category.id,
              'name': category.name,
              'color': category.color,
              'isDeleted': category.isDeleted,
            },
          )
          .toList(),
      'expenses': expenses
          .map(
            (expense) => {
              'id': expense.id,
              'categoryId': expense.categoryId,
              'amount': expense.amount,
              'note': expense.note,
              'expenseDate': expense.expenseDate.toIso8601String(),
              'isDeleted': expense.isDeleted,
              'createdAt': expense.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'incomes': incomes
          .map(
            (income) => {
              'id': income.id,
              'amount': income.amount,
              'source': income.source,
              'note': income.note,
              'incomeDate': income.incomeDate.toIso8601String(),
              'isDeleted': income.isDeleted,
              'createdAt': income.createdAt.toIso8601String(),
            },
          )
          .toList(),
    };

    final backupFile = File(backupPath);
    await backupFile.writeAsString(jsonEncode(backupPayload));
    return backupFile;
  }

  Future<void> restoreBackupFromPath({
    required String backupPath,
    required AppDatabase database,
  }) async {
    final backupFile = File(backupPath);

    if (!await backupFile.exists()) {
      throw Exception('Selected backup file does not exist.');
    }

    final rawContent = await backupFile.readAsString();
    final decoded = jsonDecode(rawContent);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid backup format.');
    }

    final categoriesRaw = decoded['categories'];
    final expensesRaw = decoded['expenses'];
    final incomesRaw = decoded['incomes'];

    if (categoriesRaw is! List || expensesRaw is! List) {
      throw Exception('Backup data is missing categories or expenses.');
    }

    final parsedIncomes = incomesRaw is List ? incomesRaw : const [];

    await database.transaction(() async {
      await database.delete(database.incomes).go();
      await database.delete(database.expenses).go();
      await database.delete(database.categories).go();

      for (final item in categoriesRaw) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.categories)
            .insert(
              CategoriesCompanion.insert(
                id: item['id'] as String,
                name: item['name'] as String,
                color: Value(item['color'] as int?),
                isDeleted: Value(item['isDeleted'] as bool? ?? false),
              ),
            );
      }

      for (final item in expensesRaw) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.expenses)
            .insert(
              ExpensesCompanion.insert(
                id: item['id'] as String,
                categoryId: item['categoryId'] as String,
                amount: (item['amount'] as num).toDouble(),
                note: Value(item['note'] as String?),
                expenseDate: DateTime.parse(item['expenseDate'] as String),
                isDeleted: Value(item['isDeleted'] as bool? ?? false),
                createdAt: Value(DateTime.parse(item['createdAt'] as String)),
              ),
            );
      }

      for (final item in parsedIncomes) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.incomes)
            .insert(
              IncomesCompanion.insert(
                id: item['id'] as String,
                amount: (item['amount'] as num).toDouble(),
                source: Value(item['source'] as String?),
                note: Value(item['note'] as String?),
                incomeDate: DateTime.parse(item['incomeDate'] as String),
                isDeleted: Value(item['isDeleted'] as bool? ?? false),
                createdAt: Value(
                  item['createdAt'] != null
                      ? DateTime.parse(item['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }
    });
  }
}
