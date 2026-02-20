import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'app_database.dart';

class DatabaseBackupService {
  Future<File> createBackupFile(AppDatabase database) async {
    final categories = await database.select(database.expenseCategories).get();
    final incomeSources = await database.select(database.incomeSources).get();
    final expenses = await database.select(database.expenses).get();
    final incomes = await database.select(database.incomes).get();
    final lends = await database.select(database.lends).get();
    final borrows = await database.select(database.borrows).get();

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupPath = p.join(tempDir.path, 'exptra-backup-$timestamp.exptra');

    final backupPayload = {
      'version': 1,
      'exportedAt': DateTime.now().toIso8601String(),
      'categories': categories
          .map(
            (category) => {
              'id': category.id,
              'name': category.name,
              'color': category.color,
              'sortOrder': category.sortOrder,
              'isDeleted': category.isDeleted,
            },
          )
          .toList(),
      'incomeSources': incomeSources
          .map(
            (source) => {
              'id': source.id,
              'name': source.name,
              'color': source.color,
              'sortOrder': source.sortOrder,
              'isDeleted': source.isDeleted,
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
              'sourceId': income.sourceId,
              'source': income.source,
              'note': income.note,
              'incomeDate': income.incomeDate.toIso8601String(),
              'isDeleted': income.isDeleted,
              'createdAt': income.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'lends': lends
          .map(
            (lend) => {
              'id': lend.id,
              'personName': lend.personName,
              'amount': lend.amount,
              'note': lend.note,
              'lendDate': lend.lendDate.toIso8601String(),
              'isSettled': lend.isSettled,
              'isDeleted': lend.isDeleted,
              'createdAt': lend.createdAt.toIso8601String(),
            },
          )
          .toList(),
      'borrows': borrows
          .map(
            (borrow) => {
              'id': borrow.id,
              'personName': borrow.personName,
              'amount': borrow.amount,
              'note': borrow.note,
              'borrowDate': borrow.borrowDate.toIso8601String(),
              'isSettled': borrow.isSettled,
              'isDeleted': borrow.isDeleted,
              'createdAt': borrow.createdAt.toIso8601String(),
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
    final incomeSourcesRaw = decoded['incomeSources'];
    final expensesRaw = decoded['expenses'];
    final incomesRaw = decoded['incomes'];
    final lendsRaw = decoded['lends'];
    final borrowsRaw = decoded['borrows'];

    if (categoriesRaw is! List || expensesRaw is! List) {
      throw Exception('Backup data is missing categories or expenses.');
    }

    final parsedIncomes = incomesRaw is List ? incomesRaw : const [];
    final parsedIncomeSources = incomeSourcesRaw is List
        ? incomeSourcesRaw
        : const [];
    final parsedLends = lendsRaw is List ? lendsRaw : const [];
    final parsedBorrows = borrowsRaw is List ? borrowsRaw : const [];

    await database.transaction(() async {
      await database.delete(database.borrows).go();
      await database.delete(database.lends).go();
      await database.delete(database.incomes).go();
      await database.delete(database.incomeSources).go();
      await database.delete(database.expenses).go();
      await database.delete(database.expenseCategories).go();

      for (final item in categoriesRaw) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.expenseCategories)
            .insert(
              ExpenseCategoriesCompanion.insert(
                id: item['id'] as String,
                name: item['name'] as String,
                color: Value(item['color'] as int?),
                sortOrder: Value(item['sortOrder'] as int? ?? 0),
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
                createdAt: Value(
                  item['createdAt'] != null
                      ? DateTime.parse(item['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      for (final item in parsedIncomeSources) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.incomeSources)
            .insert(
              IncomeSourcesCompanion.insert(
                id: item['id'] as String,
                name: item['name'] as String,
                color: Value(item['color'] as int?),
                sortOrder: Value(item['sortOrder'] as int? ?? 0),
                isDeleted: Value(item['isDeleted'] as bool? ?? false),
              ),
            );
      }

      final legacySourceMap = <String, String>{};

      for (final item in parsedIncomes) {
        if (item is! Map<String, dynamic>) continue;

        String? sourceId = item['sourceId'] as String?;
        final sourceName = (item['source'] as String?)?.trim();

        if ((sourceId == null || sourceId.isEmpty) &&
            sourceName != null &&
            sourceName.isNotEmpty) {
          final existingId = legacySourceMap[sourceName];
          if (existingId != null) {
            sourceId = existingId;
          } else {
            final generatedId =
                'legacy-${sourceName.toLowerCase().replaceAll(' ', '-')}-${legacySourceMap.length + 1}';
            legacySourceMap[sourceName] = generatedId;
            sourceId = generatedId;
            await database
                .into(database.incomeSources)
                .insert(
                  IncomeSourcesCompanion.insert(
                    id: generatedId,
                    name: sourceName,
                    color: const Value(0xFF4CAF50),
                  ),
                );
          }
        }

        await database
            .into(database.incomes)
            .insert(
              IncomesCompanion.insert(
                id: item['id'] as String,
                amount: (item['amount'] as num).toDouble(),
                sourceId: Value(sourceId),
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

      for (final item in parsedLends) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.lends)
            .insert(
              LendsCompanion.insert(
                id: item['id'] as String,
                personName: item['personName'] as String,
                amount: (item['amount'] as num).toDouble(),
                note: Value(item['note'] as String?),
                lendDate: DateTime.parse(item['lendDate'] as String),
                isSettled: Value(item['isSettled'] as bool? ?? false),
                isDeleted: Value(item['isDeleted'] as bool? ?? false),
                createdAt: Value(
                  item['createdAt'] != null
                      ? DateTime.parse(item['createdAt'] as String)
                      : DateTime.now(),
                ),
              ),
            );
      }

      for (final item in parsedBorrows) {
        if (item is! Map<String, dynamic>) continue;

        await database
            .into(database.borrows)
            .insert(
              BorrowsCompanion.insert(
                id: item['id'] as String,
                personName: item['personName'] as String,
                amount: (item['amount'] as num).toDouble(),
                note: Value(item['note'] as String?),
                borrowDate: DateTime.parse(item['borrowDate'] as String),
                isSettled: Value(item['isSettled'] as bool? ?? false),
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
