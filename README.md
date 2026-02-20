# EXPTRA

EXPTRA is a Flutter app for tracking income, expenses, lend, and borrow activity with local-first data storage.

## Overview

- Built with Flutter + GetX + Drift (SQLite)
- Uses a modular feature structure with controllers and repositories
- Stores data locally and supports backup/restore through `.exptra` files
- Includes summary reporting for income, expense, lend, and borrow data

## Features

### Transactions

- Add and delete income and expense entries
- Add and delete lend and borrow entries by person
- View chronological transaction history from the dashboard
- Filter dashboard list by `All`, `Inc/Exp`, and `Len/Bor`

### Dashboard

- Current balance summary card
- Totals for income, expense, borrowed, and lent
- Empty-state UX when no entries exist

### Categories and Sources

- Manage expense categories (add, update, delete, reorder)
- Manage income sources (add, update, delete, reorder)
- Auto-seeds defaults on first app launch
  - 7 default expense categories
  - 7 default income sources

### Reports

- Report types: `Daily`, `Month`, and `Category/Source/Person`
- Data scopes: `Income`, `Expense`, `Lend`, `Borrow`
- Month navigation for non-month-wise views
- Total amount + transaction count summary

### Backup and Restore

- Backup local DB to a portable `.exptra` file
- Share backup file via system share sheet
- Restore data from a selected backup file

## Tech Stack

- Flutter / Dart (`sdk: ^3.10.3`)
- GetX (`^4.7.3`)
- Drift + drift_flutter (`^2.31.0`, `^0.2.8`)
- sqlite3_flutter_libs (`^0.5.41`)
- intl (`^0.20.2`)
- file_picker (`^10.3.2`)
- share_plus (`^11.1.0`)

## Project Structure

```text
lib/
├── main.dart
├── core/
│   ├── constants/
│   ├── db/
│   ├── routes/
│   ├── theme/
│   └── utils/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
└── modules/
    ├── dashboard/
    ├── income_expense/
    ├── lend_borrow/
    ├── expense_category/
    ├── income_source/
    ├── reports/
    ├── settings/
    └── navigation/
```

## Getting Started

### Prerequisites

- Flutter SDK compatible with Dart `^3.10.3`
- Xcode (for iOS builds) and/or Android SDK

### Setup

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter run
```

## Development Commands

```bash
# Analyze code
flutter analyze

# Run tests
flutter test

# Re-generate drift/build_runner files
dart run build_runner build --delete-conflicting-outputs
```

## Data Notes

- Currency defaults to BDT (`৳`) in app constants
- Database uses soft-delete flags for records
- Category/source delete is blocked when entries still reference them

## License

Private project by shahedpy.

