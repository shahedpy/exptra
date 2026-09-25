import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../../core/db/app_database.dart';
import '../services/financial_calculator.dart';
import 'account_type_repository.dart';

class AccountingRepository {
  final AppDatabase db;
  static const _uuid = Uuid();
  AccountingRepository(this.db);

  Future<FinancialCalculator> calculator() async => FinancialCalculator(
    accounts: await db.select(db.accounts).get(),
    accountTypes: await db.select(db.accountTypes).get(),
    incomes: await db.select(db.incomes).get(),
    categories: await db.select(db.expenseCategories).get(),
    sources: await db.select(db.incomeSources).get(),
    expenses: await db.select(db.expenses).get(),
    lends: await db.select(db.lends).get(),
    borrows: await db.select(db.borrows).get(),
    transfers: await db.select(db.accountTransfers).get(),
    lendRepayments: await db.select(db.lendRepayments).get(),
    borrowRepayments: await db.select(db.borrowRepayments).get(),
    adjustments: await db.select(db.balanceAdjustments).get(),
  );

  Future<List<Account>> accounts({bool includeArchived = false}) async {
    final rows =
        await (db.select(db.accounts)
              ..where((t) => t.isDeleted.equals(false))
              ..orderBy([
                (t) => OrderingTerm.asc(t.sortOrder),
                (t) => OrderingTerm.asc(t.name),
              ]))
            .get();
    return includeArchived ? rows : rows.where((a) => !a.isArchived).toList();
  }

  Future<void> saveAccount({
    String? id,
    required String institutionName,
    required String name,
    required String type,
    String? accountTypeId,
    String currency = 'BDT',
    required double openingBalance,
    required DateTime openingBalanceDate,
    String? note,
    int sortOrder = 0,
    bool includeInNetWorth = true,
    bool isArchived = false,
  }) async {
    final typeRepository = AccountTypeRepository(db);
    final accountType = accountTypeId == null
        ? await typeRepository.resolveLegacy(type)
        : await (db.select(db.accountTypes)..where(
                (t) => t.id.equals(accountTypeId) & t.isDeleted.equals(false),
              ))
              .getSingle();
    final existing = id == null
        ? null
        : await (db.select(
            db.accounts,
          )..where((t) => t.id.equals(id))).getSingleOrNull();
    if (existing != null) {
      await (db.update(db.accounts)..where((t) => t.id.equals(id!))).write(
        AccountsCompanion(
          institutionName: Value(institutionName),
          name: Value(name),
          type: Value(accountType.name),
          accountTypeId: Value(accountType.id),
          currency: Value(currency),
          openingBalance: Value(Money.normalize(openingBalance)),
          openingBalanceDate: Value(openingBalanceDate),
          note: Value(note),
          sortOrder: Value(sortOrder),
          includeInNetWorth: Value(includeInNetWorth),
          isArchived: Value(isArchived),
        ),
      );
    } else {
      await db
          .into(db.accounts)
          .insert(
            AccountsCompanion.insert(
              id: id ?? _uuid.v4(),
              institutionName: Value(institutionName),
              name: name,
              type: accountType.name,
              accountTypeId: Value(accountType.id),
              currency: Value(currency),
              openingBalance: Value(Money.normalize(openingBalance)),
              openingBalanceDate: openingBalanceDate,
              note: Value(note),
              sortOrder: Value(sortOrder),
              includeInNetWorth: Value(includeInNetWorth),
              isArchived: Value(isArchived),
            ),
          );
    }
  }

  Future<void> archiveAccount(String id, bool archived) =>
      (db.update(db.accounts)..where((t) => t.id.equals(id))).write(
        AccountsCompanion(isArchived: Value(archived)),
      );

  Future<void> reorder(List<Account> accounts) async =>
      db.transaction(() async {
        for (var i = 0; i < accounts.length; i++) {
          await (db.update(db.accounts)
                ..where((t) => t.id.equals(accounts[i].id)))
              .write(AccountsCompanion(sortOrder: Value(i)));
        }
      });

  Future<void> transfer({
    required String fromId,
    required String toId,
    required double amount,
    double fee = 0,
    String? note,
    required DateTime date,
  }) async {
    if (fromId == toId || amount <= 0 || fee < 0) {
      throw ArgumentError('Invalid transfer');
    }
    await db
        .into(db.accountTransfers)
        .insert(
          AccountTransfersCompanion.insert(
            id: _uuid.v4(),
            fromAccountId: fromId,
            toAccountId: toId,
            amount: Money.normalize(amount),
            fee: Value(Money.normalize(fee)),
            note: Value(note),
            transferDate: date,
          ),
        );
  }

  Future<void> repayLend({
    required String lendId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await db.transaction(() async {
      final row = await (db.select(
        db.lends,
      )..where((t) => t.id.equals(lendId))).getSingle();
      final calc = await calculator();
      if (row.isDeleted ||
          row.isSettled ||
          Money.cents(amount) <= 0 ||
          Money.cents(amount) > calc.outstandingLend(row) ||
          DateTime(date.year, date.month, date.day).isBefore(
            DateTime(row.lendDate.year, row.lendDate.month, row.lendDate.day),
          )) {
        throw ArgumentError(
          'Repayment exceeds outstanding amount or has an invalid date',
        );
      }
      await db
          .into(db.lendRepayments)
          .insert(
            LendRepaymentsCompanion.insert(
              id: _uuid.v4(),
              lendId: lendId,
              accountId: Value(accountId),
              amount: Money.normalize(amount),
              repaymentDate: date,
              note: Value(note),
            ),
          );
    });
  }

  Future<void> repayBorrow({
    required String borrowId,
    required String accountId,
    required double amount,
    required DateTime date,
    String? note,
  }) async {
    await db.transaction(() async {
      final row = await (db.select(
        db.borrows,
      )..where((t) => t.id.equals(borrowId))).getSingle();
      final calc = await calculator();
      if (row.isDeleted ||
          row.isSettled ||
          Money.cents(amount) <= 0 ||
          Money.cents(amount) > calc.outstandingBorrow(row) ||
          DateTime(date.year, date.month, date.day).isBefore(
            DateTime(
              row.borrowDate.year,
              row.borrowDate.month,
              row.borrowDate.day,
            ),
          )) {
        throw ArgumentError(
          'Repayment exceeds outstanding amount or has an invalid date',
        );
      }
      await db
          .into(db.borrowRepayments)
          .insert(
            BorrowRepaymentsCompanion.insert(
              id: _uuid.v4(),
              borrowId: borrowId,
              accountId: Value(accountId),
              amount: Money.normalize(amount),
              repaymentDate: date,
              note: Value(note),
            ),
          );
    });
  }

  Future<AccountBalanceSnapshot> recordSnapshot({
    required String accountId,
    required DateTime date,
    required double actual,
    String? note,
  }) async {
    final calc = await calculator();
    final account = calc.accounts.firstWhere(
      (a) => a.id == accountId && !a.isDeleted,
    );
    final calculated = calc.balanceOf(account, through: date);
    final actualCents = Money.cents(actual);
    final id = _uuid.v4();
    await db
        .into(db.accountBalanceSnapshots)
        .insert(
          AccountBalanceSnapshotsCompanion.insert(
            id: id,
            accountId: accountId,
            date: date,
            actualBalance: Money.bdt(actualCents),
            calculatedBalance: Money.bdt(calculated),
            difference: Money.bdt(actualCents - calculated),
            note: Value(note),
          ),
        );
    return (db.select(
      db.accountBalanceSnapshots,
    )..where((t) => t.id.equals(id))).getSingle();
  }

  Future<void> adjustSnapshot(AccountBalanceSnapshot snapshot) async {
    if (snapshot.isDeleted || Money.cents(snapshot.difference) == 0) return;
    final existing =
        await (db.select(db.balanceAdjustments)..where(
              (t) =>
                  t.snapshotId.equals(snapshot.id) & t.isDeleted.equals(false),
            ))
            .getSingleOrNull();
    if (existing != null) throw StateError('Snapshot already adjusted');
    await db
        .into(db.balanceAdjustments)
        .insert(
          BalanceAdjustmentsCompanion.insert(
            id: _uuid.v4(),
            accountId: snapshot.accountId,
            snapshotId: Value(snapshot.id),
            date: snapshot.date,
            amount: Money.normalize(snapshot.difference),
            note: Value('Reconciliation adjustment'),
          ),
        );
  }

  Future<List<AccountBalanceSnapshot>> snapshots(String accountId) =>
      (db.select(db.accountBalanceSnapshots)
            ..where(
              (t) => t.accountId.equals(accountId) & t.isDeleted.equals(false),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)]))
          .get();
}
