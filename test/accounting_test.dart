import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:exptra/core/db/app_database.dart';
import 'package:exptra/core/db/database_backup_service.dart';
import 'package:exptra/data/repositories/accounting_repository.dart';
import 'package:exptra/data/repositories/income_repository.dart';
import 'package:exptra/data/repositories/expense_repository.dart';
import 'package:exptra/data/repositories/lend_repository.dart';
import 'package:exptra/data/repositories/borrow_repository.dart';
import 'package:exptra/data/services/financial_calculator.dart';

void main() {
  late AppDatabase db;
  late AccountingRepository accounting;
  final day1 = DateTime(2026, 8, 7);
  final day2 = DateTime(2026, 9, 24);

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    accounting = AccountingRepository(db);
  });
  tearDown(() async => db.close());

  Future<Account> account(String name, double opening) async {
    await accounting.saveAccount(
      institutionName: 'Test Bank',
      name: name,
      type: 'Savings',
      openingBalance: opening,
      openingBalanceDate: day1,
    );
    return (await accounting.accounts()).firstWhere((a) => a.name == name);
  }

  test('income, expense, transfer, and dated balances', () async {
    final a = await account('A', 10000);
    final b = await account('B', 5000);
    await db
        .into(db.expenseCategories)
        .insert(ExpenseCategoriesCompanion.insert(id: 'cat', name: 'Rent'));
    await IncomeRepository(
      db,
    ).insertIncome(amount: 5000, accountId: a.id, date: day2, source: 'Salary');
    await ExpenseRepository(db).insertExpense(
      categoryId: 'cat',
      amount: 3000,
      accountId: a.id,
      date: day2,
    );
    var calc = await accounting.calculator();
    expect(calc.balanceOf(a), 1200000);
    expect(calc.balanceOf(a, through: day1), 1000000);
    await accounting.transfer(
      fromId: a.id,
      toId: b.id,
      amount: 2000,
      date: day2,
    );
    calc = await accounting.calculator();
    expect(calc.balanceOf(a), 1000000);
    expect(calc.balanceOf(b), 700000);
    expect(calc.position().netWorth, 1700000);
    final comparison = calc.compare(day1, day2);
    expect(comparison.change, 200000);
    expect(comparison.transfers, 200000);
    expect(comparison.unexplained, 0);
    final income = (await db.select(db.incomes).get()).single;
    await IncomeRepository(db).softDelete(income.id);
    calc = await accounting.calculator();
    expect(calc.balanceOf(a), 500000);
  });

  test('lend and borrow partial repayments preserve net worth', () async {
    final cash = await account('Cash', 20000);
    await LendRepository(db).insertLend(
      personName: 'Jabed',
      amount: 5000,
      accountId: cash.id,
      date: DateTime(2026, 9, 24, 15),
    );
    var calc = await accounting.calculator();
    final lend = (await db.select(db.lends).get()).single;
    expect(calc.balanceOf(cash), 1500000);
    expect(calc.outstandingLend(lend), 500000);
    expect(calc.position().netWorth, 2000000);
    await accounting.repayLend(
      lendId: lend.id,
      accountId: cash.id,
      amount: 2000,
      date: day2,
    );
    calc = await accounting.calculator();
    expect(calc.balanceOf(cash), 1700000);
    expect(calc.outstandingLend(lend), 300000);
    expect(calc.position().netWorth, 2000000);
    await BorrowRepository(db).insertBorrow(
      personName: 'Rahim',
      amount: 5000,
      accountId: cash.id,
      date: day2,
    );
    final borrow = (await db.select(db.borrows).get()).single;
    calc = await accounting.calculator();
    expect(calc.balanceOf(cash), 2200000);
    expect(calc.outstandingBorrow(borrow), 500000);
    expect(calc.position().netWorth, 2000000);
    await accounting.repayBorrow(
      borrowId: borrow.id,
      accountId: cash.id,
      amount: 2000,
      date: day2,
    );
    calc = await accounting.calculator();
    expect(calc.balanceOf(cash), 2000000);
    expect(calc.outstandingBorrow(borrow), 300000);
    expect(calc.position().netWorth, 2000000);
    await expectLater(
      accounting.repayBorrow(
        borrowId: borrow.id,
        accountId: cash.id,
        amount: 4000,
        date: day2,
      ),
      throwsArgumentError,
    );
  });

  test('balance check is passive until explicit adjustment', () async {
    final a = await account('A', 10000);
    final snapshot = await accounting.recordSnapshot(
      accountId: a.id,
      date: day2,
      actual: 10535,
      note: 'Bank balance',
    );
    expect(Money.cents(snapshot.difference), 53500);
    expect((await accounting.calculator()).balanceOf(a), 1000000);
    await accounting.adjustSnapshot(snapshot);
    expect((await accounting.calculator()).balanceOf(a), 1053500);
    await expectLater(accounting.adjustSnapshot(snapshot), throwsStateError);
  });

  test(
    'v2 backup restores accounts and transfer; v1 stays unassigned',
    () async {
      final a = await account('A', 10000);
      final b = await account('B', 0);
      await accounting.transfer(
        fromId: a.id,
        toId: b.id,
        amount: 500,
        date: day2,
      );
      final temp = await Directory.systemTemp.createTemp('exptra-test-');
      try {
        final service = DatabaseBackupService();
        final file = await service.createBackupFile(
          db,
          outputPath: '${temp.path}/new.exptra',
        );
        final payload =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        expect(payload['version'], 2);
        await service.restoreBackupFromPath(
          backupPath: file.path,
          database: db,
        );
        expect((await accounting.calculator()).position().netWorth, 1000000);
        expect((await db.select(db.accountTransfers).get()).length, 1);
        final oldFile = File('${temp.path}/old.exptra');
        await oldFile.writeAsString(
          jsonEncode({
            'version': 1,
            'categories': [
              {'id': 'cat', 'name': 'Rent'},
            ],
            'expenses': [
              {
                'id': 'expense',
                'categoryId': 'cat',
                'amount': 100.0,
                'expenseDate': day2.toIso8601String(),
              },
            ],
            'incomes': [
              {
                'id': 'income',
                'amount': 1000.0,
                'incomeDate': day2.toIso8601String(),
              },
            ],
          }),
        );
        await service.restoreBackupFromPath(
          backupPath: oldFile.path,
          database: db,
        );
        expect((await accounting.accounts()).isEmpty, true);
        expect((await db.select(db.incomes).get()).single.accountId, isNull);
        expect((await db.select(db.expenses).get()).single.accountId, isNull);
      } finally {
        await temp.delete(recursive: true);
      }
    },
  );

  test('v1 schema migrates without assigning old income', () async {
    await db.close();
    db = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (raw) {
          raw.execute(
            'CREATE TABLE expense_categories (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, color INTEGER, sort_order INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0)',
          );
          raw.execute(
            'CREATE TABLE income_sources (id TEXT NOT NULL PRIMARY KEY, name TEXT NOT NULL, color INTEGER, sort_order INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0)',
          );
          raw.execute(
            'CREATE TABLE expenses (id TEXT NOT NULL PRIMARY KEY, category_id TEXT NOT NULL, amount REAL NOT NULL, note TEXT, expense_date INTEGER NOT NULL, is_deleted INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')))',
          );
          raw.execute(
            'CREATE TABLE incomes (id TEXT NOT NULL PRIMARY KEY, amount REAL NOT NULL, source_id TEXT, source TEXT, note TEXT, income_date INTEGER NOT NULL, is_deleted INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')))',
          );
          raw.execute(
            'CREATE TABLE lends (id TEXT NOT NULL PRIMARY KEY, person_name TEXT NOT NULL, amount REAL NOT NULL, note TEXT, lend_date INTEGER NOT NULL, is_settled INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')))',
          );
          raw.execute(
            'CREATE TABLE borrows (id TEXT NOT NULL PRIMARY KEY, person_name TEXT NOT NULL, amount REAL NOT NULL, note TEXT, borrow_date INTEGER NOT NULL, is_settled INTEGER NOT NULL DEFAULT 0, is_deleted INTEGER NOT NULL DEFAULT 0, created_at INTEGER NOT NULL DEFAULT (strftime(\'%s\', \'now\')))',
          );
          raw.execute(
            "INSERT INTO incomes (id,amount,income_date) VALUES ('legacy',123.45,1788739200)",
          );
          raw.execute('PRAGMA user_version = 1');
        },
      ),
    );
    accounting = AccountingRepository(db);
    final rows = await db.select(db.incomes).get();
    expect(rows.single.amount, 123.45);
    expect(rows.single.accountId, isNull);
    expect(await accounting.accounts(), isEmpty);
  });
}
