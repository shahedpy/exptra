import '../../core/db/app_database.dart';
import '../models/account_type_defaults.dart';

/// Existing Drift REAL values remain on disk for backwards compatibility.
/// Every amount enters calculations as rounded integer poisha; totals are
/// converted to BDT only at the UI boundary.
class Money {
  static int cents(double value) => (value * 100).round();
  static double bdt(int cents) => cents / 100;
  static double normalize(double value) => bdt(cents(value));
}

class LedgerEntry {
  final String id;
  final String accountId;
  final DateTime date;
  final String type;
  final String title;
  final String? note;
  final int amount;
  final String? categoryId;
  final String? sourceId;
  final String? person;

  const LedgerEntry({
    required this.id,
    required this.accountId,
    required this.date,
    required this.type,
    required this.title,
    required this.amount,
    this.note,
    this.categoryId,
    this.sourceId,
    this.person,
  });
}

class FinancialPosition {
  final int bankAndCash;
  final int investments;
  final int otherAssets;
  final int receivables;
  final int liabilities;
  final int excludedAssets;

  const FinancialPosition(
    this.bankAndCash,
    this.investments,
    this.otherAssets,
    this.receivables,
    this.liabilities,
    this.excludedAssets,
  );
  int get netWorth =>
      bankAndCash + investments + otherAssets + receivables - liabilities;
}

class PeriodComparison {
  final FinancialPosition opening;
  final FinancialPosition closing;
  final int income,
      expense,
      moneyLent,
      lendRepayments,
      borrowed,
      borrowRepayments,
      transfers,
      adjustments;
  const PeriodComparison({
    required this.opening,
    required this.closing,
    required this.income,
    required this.expense,
    required this.moneyLent,
    required this.lendRepayments,
    required this.borrowed,
    required this.borrowRepayments,
    required this.transfers,
    required this.adjustments,
  });
  int get change => closing.netWorth - opening.netWorth;
  int get netCashFlow => income - expense;
  int get explainedChange => income - expense + adjustments;
  int get unexplained => change - explainedChange;
}

class FinancialCalculator {
  final List<Account> accounts;
  final List<AccountType> accountTypes;
  final List<Income> incomes;
  final List<ExpenseCategory> categories;
  final List<IncomeSource> sources;
  final List<Expense> expenses;
  final List<Lend> lends;
  final List<Borrow> borrows;
  final List<AccountTransfer> transfers;
  final List<LendRepayment> lendRepayments;
  final List<BorrowRepayment> borrowRepayments;
  final List<BalanceAdjustment> adjustments;

  const FinancialCalculator({
    required this.accounts,
    required this.accountTypes,
    required this.incomes,
    required this.categories,
    required this.sources,
    required this.expenses,
    required this.lends,
    required this.borrows,
    required this.transfers,
    required this.lendRepayments,
    required this.borrowRepayments,
    required this.adjustments,
  });

  String classificationOf(Account account) {
    for (final type in accountTypes) {
      if (type.id == account.accountTypeId) return type.classification;
    }
    return AccountTypeClass.other;
  }

  String typeNameOf(Account account) {
    for (final type in accountTypes) {
      if (type.id == account.accountTypeId) return type.name;
    }
    return account.type;
  }

  static bool _through(DateTime date, DateTime? end) =>
      end == null ||
      !DateTime(
        date.year,
        date.month,
        date.day,
      ).isAfter(DateTime(end.year, end.month, end.day));

  List<LedgerEntry> entriesFor(String accountId, {DateTime? through}) {
    final entries = <LedgerEntry>[];
    final accountNames = {for (final a in accounts) a.id: a.name};
    final categoryNames = {for (final c in categories) c.id: c.name};
    final sourceNames = {for (final s in sources) s.id: s.name};
    final lendNames = {for (final l in lends) l.id: l.personName};
    final borrowNames = {for (final b in borrows) b.id: b.personName};
    void add(
      String id,
      DateTime date,
      String type,
      String title,
      double amount,
      String? note, {
      String? categoryId,
      String? sourceId,
      String? person,
    }) {
      if (_through(date, through)) {
        entries.add(
          LedgerEntry(
            id: id,
            accountId: accountId,
            date: date,
            type: type,
            title: title,
            amount: Money.cents(amount),
            note: note,
            categoryId: categoryId,
            sourceId: sourceId,
            person: person,
          ),
        );
      }
    }

    for (final item in incomes) {
      if (!item.isDeleted && item.accountId == accountId) {
        add(
          item.id,
          item.incomeDate,
          'income',
          sourceNames[item.sourceId] ?? item.source ?? 'Income',
          item.amount,
          item.note,
          sourceId: item.sourceId,
        );
      }
    }
    for (final item in expenses) {
      if (!item.isDeleted && item.accountId == accountId) {
        add(
          item.id,
          item.expenseDate,
          'expense',
          categoryNames[item.categoryId] ?? 'Expense',
          -item.amount,
          item.note,
          categoryId: item.categoryId,
        );
      }
    }
    for (final item in transfers) {
      if (item.isDeleted) {
        continue;
      }
      if (item.fromAccountId == accountId) {
        add(
          item.id,
          item.transferDate,
          'transfer',
          'Transfer to ${accountNames[item.toAccountId] ?? 'account'}',
          -item.amount,
          item.note,
        );
        if (item.fee != 0) {
          add(
            '${item.id}:fee',
            item.transferDate,
            'expense',
            'Transfer fee',
            -item.fee,
            item.note,
          );
        }
      }
      if (item.toAccountId == accountId) {
        add(
          item.id,
          item.transferDate,
          'transfer',
          'Transfer from ${accountNames[item.fromAccountId] ?? 'account'}',
          item.amount,
          item.note,
        );
      }
    }
    for (final item in lends) {
      if (!item.isDeleted && item.accountId == accountId) {
        add(
          item.id,
          item.lendDate,
          'lend',
          'Lent to ${item.personName}',
          -item.amount,
          item.note,
          person: item.personName,
        );
      }
    }
    for (final item in lendRepayments) {
      if (!item.isDeleted &&
          item.accountId == accountId &&
          lends.any((l) => l.id == item.lendId && !l.isDeleted)) {
        add(
          item.id,
          item.repaymentDate,
          'lend',
          '${lendNames[item.lendId] ?? 'Lend'} repayment',
          item.amount,
          item.note,
        );
      }
    }
    for (final item in borrows) {
      if (!item.isDeleted && item.accountId == accountId) {
        add(
          item.id,
          item.borrowDate,
          'borrow',
          'Borrowed from ${item.personName}',
          item.amount,
          item.note,
          person: item.personName,
        );
      }
    }
    for (final item in borrowRepayments) {
      if (!item.isDeleted &&
          item.accountId == accountId &&
          borrows.any((b) => b.id == item.borrowId && !b.isDeleted)) {
        add(
          item.id,
          item.repaymentDate,
          'borrow',
          '${borrowNames[item.borrowId] ?? 'Borrow'} repayment',
          -item.amount,
          item.note,
        );
      }
    }
    for (final item in adjustments) {
      if (!item.isDeleted && item.accountId == accountId) {
        add(
          item.id,
          item.date,
          'adjustment',
          'Balance adjustment',
          item.amount,
          item.note,
        );
      }
    }
    entries.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });
    return entries;
  }

  int balanceOf(Account account, {DateTime? through}) {
    if (account.isDeleted || !_through(account.openingBalanceDate, through)) {
      return 0;
    }
    return Money.cents(account.openingBalance) +
        entriesFor(account.id, through: through)
            .where((e) => !e.date.isBefore(account.openingBalanceDate))
            .fold<int>(0, (s, e) => s + e.amount);
  }

  int outstandingLend(Lend lend, {DateTime? through}) {
    if (lend.isDeleted || !_through(lend.lendDate, through)) return 0;
    final repaid = lendRepayments
        .where(
          (r) =>
              !r.isDeleted &&
              r.lendId == lend.id &&
              _through(r.repaymentDate, through),
        )
        .fold<int>(0, (s, r) => s + Money.cents(r.amount));
    if (lend.isSettled && repaid == 0) {
      return 0; // Legacy settled row has no dated repayment.
    }
    return (Money.cents(lend.amount) - repaid).clamp(
      0,
      Money.cents(lend.amount),
    );
  }

  int outstandingBorrow(Borrow borrow, {DateTime? through}) {
    if (borrow.isDeleted || !_through(borrow.borrowDate, through)) return 0;
    final repaid = borrowRepayments
        .where(
          (r) =>
              !r.isDeleted &&
              r.borrowId == borrow.id &&
              _through(r.repaymentDate, through),
        )
        .fold<int>(0, (s, r) => s + Money.cents(r.amount));
    if (borrow.isSettled && repaid == 0) return 0;
    return (Money.cents(borrow.amount) - repaid).clamp(
      0,
      Money.cents(borrow.amount),
    );
  }

  FinancialPosition position({DateTime? through}) {
    var cash = 0, investment = 0, other = 0, excluded = 0;
    for (final account in accounts.where((a) => !a.isDeleted)) {
      final value = balanceOf(account, through: through);
      if (!account.includeInNetWorth) {
        excluded += value;
        continue;
      }
      switch (classificationOf(account)) {
        case AccountTypeClass.liquid:
          cash += value;
        case AccountTypeClass.investment:
          investment += value;
        default:
          other += value;
      }
    }
    return FinancialPosition(
      cash,
      investment,
      other,
      lends.fold<int>(0, (s, l) => s + outstandingLend(l, through: through)),
      borrows.fold<int>(
        0,
        (s, b) => s + outstandingBorrow(b, through: through),
      ),
      excluded,
    );
  }

  PeriodComparison compare(DateTime from, DateTime to) {
    if (to.isBefore(from)) {
      throw ArgumentError('To date must be after from date');
    }
    bool during(DateTime d) =>
        DateTime(
          d.year,
          d.month,
          d.day,
        ).isAfter(DateTime(from.year, from.month, from.day)) &&
        _through(d, to);
    int sum<T>(
      Iterable<T> rows,
      DateTime Function(T) date,
      double Function(T) amount,
    ) => rows
        .where((r) => during(date(r)))
        .fold<int>(0, (s, r) => s + Money.cents(amount(r)));
    return PeriodComparison(
      opening: position(through: from),
      closing: position(through: to),
      income: sum(
        incomes.where((r) => !r.isDeleted),
        (r) => r.incomeDate,
        (r) => r.amount,
      ),
      expense:
          sum(
            expenses.where((r) => !r.isDeleted),
            (r) => r.expenseDate,
            (r) => r.amount,
          ) +
          sum(
            transfers.where((r) => !r.isDeleted),
            (r) => r.transferDate,
            (r) => r.fee,
          ),
      moneyLent: sum(
        lends.where((r) => !r.isDeleted),
        (r) => r.lendDate,
        (r) => r.amount,
      ),
      lendRepayments: sum(
        lendRepayments.where((r) => !r.isDeleted),
        (r) => r.repaymentDate,
        (r) => r.amount,
      ),
      borrowed: sum(
        borrows.where((r) => !r.isDeleted),
        (r) => r.borrowDate,
        (r) => r.amount,
      ),
      borrowRepayments: sum(
        borrowRepayments.where((r) => !r.isDeleted),
        (r) => r.repaymentDate,
        (r) => r.amount,
      ),
      transfers: sum(
        transfers.where((r) => !r.isDeleted),
        (r) => r.transferDate,
        (r) => r.amount,
      ),
      adjustments: sum(
        adjustments.where((r) => !r.isDeleted),
        (r) => r.date,
        (r) => r.amount,
      ),
    );
  }
}
