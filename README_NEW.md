# EXPTRA - Expense Tracker App

A comprehensive Flutter expense tracking application with category management, built using GetX state management and Drift for database operations.

## Features

✅ **Expense Management**
- Add, view, and delete expenses
- Categorize expenses
- Add optional notes to expenses
- Pick custom dates for expenses
- Formatted currency display with USD symbol

✅ **Category Management**
- View all categories
- Add custom categories with color selection
- Edit existing categories
- Delete categories (with expense count validation)
- Pre-seeded default categories on first launch
  - Food, Transport, Entertainment, Shopping, Bills, Health, Other

✅ **Dashboard**
- Visual summary of total expenses
- Transaction count display
- Average expense calculation
- Expense list with category names and colors
- Quick delete functionality with confirmation

✅ **User Interface**
- Material Design 3 with modern theming
- Light and dark mode support
- Color-coded categories for easy identification
- Form validation for all inputs
- Responsive design

✅ **Data Persistence**
- Local SQLite database via Drift ORM
- Soft delete for expenses and categories
- Automatic schema management

## Project Structure

```
lib/
├── main.dart                          # App entry point
├── core/
│   ├── constants/
│   │   └── app_constants.dart        # App-wide constants and configurations
│   ├── db/
│   │   ├── app_database.dart         # Drift database setup
│   │   ├── app_database.g.dart       # Generated database code
│   │   └── tables/
│   │       ├── expense_table.dart    # Expense table schema
│   │       └── category_table.dart   # Category table schema
│   ├── routes/
│   │   └── app_routes.dart           # GetX route configuration
│   ├── theme/
│   │   └── app_theme.dart            # App themes (light/dark)
│   └── utils/
│       └── helpers.dart              # Helper utilities (date, currency, validation, color)
├── data/
│   ├── models/
│   │   └── expense_model.dart        # Expense data model
│   ├── repositories/
│   │   ├── expense_repository.dart   # Expense CRUD operations
│   │   └── category_repository.dart  # Category CRUD operations
│   └── datasources/                  # Placeholder for future datasources
└── modules/
    ├── dashboard/
    │   ├── dashboard_page.dart       # Dashboard UI
    │   └── dashboard_controller.dart # Dashboard state management
    ├── expense/
    │   ├── expense_controller.dart   # Expense state management
    │   └── add_expense_page.dart     # Add expense form
    ├── category/
    │   ├── category_controller.dart  # Category state management
    │   └── category_page.dart        # Category management UI
    └── settings/                      # Placeholder for settings module
```

## Technology Stack

- **Flutter 3.10.3+** - UI framework
- **Dart 3.10.3+** - Programming language
- **GetX 4.7.3** - State management and routing
- **Drift 2.31.0** - ORM for SQLite database
- **fl_chart 1.1.1** - Charts and graphs
- **intl 0.20.2** - Internationalization and formatting
- **uuid 4.5.2** - Unique ID generation

## Getting Started

### Prerequisites
- Flutter SDK (3.10.3 or higher)
- Dart SDK (3.10.3 or higher)

### Installation

1. **Clone the repository**
   ```bash
   cd /Users/shahed/repositories/EXPTRA
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## Usage

### Adding an Expense
1. Tap the **+** button on the Dashboard
2. Enter the expense amount
3. Select a category
4. Pick a date (defaults to today)
5. Optionally add notes
6. Tap "Add Expense"

### Managing Categories
1. Tap the **category icon** in the Dashboard AppBar
2. View all existing categories
3. Tap **+** to add a new category
4. Select a color and enter the category name
5. Tap the menu icon (⋮) to edit or delete

### Viewing Expenses
- **Dashboard**: Shows all expenses sorted by date (newest first)
- **Summary Card**: Displays total expenses, transaction count, and average
- **Delete**: Swipe or tap delete icon to remove an expense

## Architecture

The project follows **MVC (Model-View-Controller)** architecture with **GetX** for state management:

- **Models**: Data classes representing database entities
- **Views**: UI pages (StatefulWidget/StatelessWidget)
- **Controllers**: State management with GetX GetxController
- **Repositories**: Business logic and database operations
- **Database**: Drift ORM with SQLite

## Key Components

### AppDatabase
Drift database with two main tables:
- **Expenses**: Stores expense records with category reference
- **Categories**: Stores category definitions with color

### Controllers
- **ExpenseController**: Manages expense list and operations
- **CategoryController**: Manages category list with auto-seeding
- **DashboardController**: Calculates and displays summary statistics

### Helper Classes
- **DateHelper**: Date formatting and relative date calculations
- **CurrencyHelper**: Currency formatting and parsing
- **ColorHelper**: Color conversion and management
- **ValidationHelper**: Form input validation

## Constants

All app-wide constants are defined in `app_constants.dart`:
- Currency symbol: `$`
- Date format: `dd MMM yyyy`
- Default categories with RGB colors
- Validation limits and UI dimensions
- Animation durations

## Validation Rules

- **Amount**: Required, numeric, $0.01 - $999,999.99
- **Note**: Optional, max 500 characters
- **Category Name**: 2-50 characters, required
- **Date**: Past or current date only

## Future Enhancements

Potential features to add:
- Expense editing functionality
- Date range filtering
- Expense search
- Chart visualizations (pie charts, bar graphs)
- Export to CSV/PDF
- Recurring expenses
- Budget tracking
- Multiple currency support
- Cloud backup/sync
- Receipt image attachment

## Database Notes

The app uses soft deletes for both expenses and categories:
- Deleted records are marked with `isDeleted = true`
- Records are never physically removed from the database
- This preserves data integrity and allows potential recovery

Categories are auto-seeded with 7 defaults on first app launch:
- Food, Transport, Entertainment, Shopping, Bills, Health, Other

## License

This project is a private expense tracker application by shahedpy.

## Build Command

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

This generates the necessary Drift database code from the table definitions.

