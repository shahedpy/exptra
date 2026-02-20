<div align="center">

# EXPTRA

### Modern Expense Tracker Application

A feature-rich Flutter expense tracking application with intelligent category management and comprehensive financial insights.

[![Flutter](https://img.shields.io/badge/Flutter-3.10.3+-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.10.3+-0175C2?logo=dart)](https://dart.dev)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()

</div>

---

## 📋 Overview

EXPTRA is a comprehensive expense tracking solution built with Flutter, featuring an intuitive interface and robust data management. The application employs modern architectural patterns and provides users with powerful tools to monitor their spending habits effectively.

## ✨ Key Features

### 💰 Expense, Income & Lend/Borrow Management
- **Intuitive Entry**: Quick logging for expenses, incomes, and lend/borrow transactions
- **Smart Organization**: Chronologically sorted entries with clear transaction-type indicators
- **Safe Deletion**: Confirmation dialogs with soft-delete data preservation
- **Real-time Updates**: Instant dashboard synchronization across all views

### 🏷️ Category Management
- **Pre-configured Categories**: 7 default categories auto-seeded on first launch
- **Custom Categories**: Create personalized categories with color-coded identification
- **Full CRUD Operations**: Add, edit, and remove categories with validation
- **Smart Deletion**: Prevents removal of categories currently in use

### 📊 Dashboard Analytics
- **Financial Summary**: Income, expense, borrowed, lent, and live balance overview
- **Visual Insights**: Gradient-enhanced summary cards with category color coding
- **Empty States**: Helpful guidance when no data is available
- **Quick Actions**: One-tap access to add expense, income, or lend/borrow entries

### 🎨 User Experience
- **Material Design 3**: Modern, clean interface following latest design guidelines
- **Theme Support**: Seamless light and dark mode adaptation
- **Form Validation**: Comprehensive input validation with user-friendly error messages
- **Responsive Design**: Optimized layouts for various screen sizes

## 🏗️ Architecture

The application implements a clean **MVC architecture** with clear separation of concerns:

```
┌──────────────────────────────────────┐
│      Presentation Layer              │
│   (Pages & UI Components)            │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      Controller Layer (GetX)         │
│   (State Management & Logic)         │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      Repository Layer                │
│   (Business Logic & Data Access)     │
└────────────┬─────────────────────────┘
             │
┌────────────▼─────────────────────────┐
│      Data Layer (Drift ORM)          │
│   (SQLite Database Persistence)      │
└──────────────────────────────────────┘
```

### Project Structure

```
lib/
├── main.dart                     # Application entry point
├── core/                         # Core functionality
│   ├── constants/                # App-wide constants
│   ├── db/                       # Database configuration
│   ├── routes/                   # Navigation routes
│   ├── theme/                    # Theme configuration
│   └── utils/                    # Helper utilities
├── data/                         # Data layer
│   ├── models/                   # Data models
│   └── repositories/             # Data repositories
└── modules/                      # Feature modules
    ├── dashboard/                # Dashboard feature
   ├── expense/                  # Expense management
   ├── income/                   # Income management
   ├── lend_borrow/              # Lend and borrow management
    └── category/                 # Category management
```

## 🛠️ Technology Stack

| Category | Technology | Purpose |
|----------|-----------|---------|
| **Framework** | Flutter 3.10.3+ | Cross-platform UI development |
| **Language** | Dart 3.10.3+ | Primary programming language |
| **State Management** | GetX 4.7.3 | Reactive state management |
| **Database** | Drift 2.31.0 | Type-safe SQLite ORM |
| **Local Storage** | SQLite | Persistent data storage |
| **Date/Time** | intl 0.20.2 | Internationalization and formatting |
| **UUID** | uuid 4.5.2 | Unique identifier generation |

## 🚀 Getting Started

### Prerequisites

- Flutter SDK 3.10.3 or higher
- Dart SDK 3.10.3 or higher
- IDE (VS Code, Android Studio, or IntelliJ IDEA)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd EXPTRA
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate database code**
   ```bash
   flutter pub run build_runner build --delete-conflicting-outputs
   ```

4. **Run the application**
   ```bash
   flutter run
   ```

### Build for Production

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release

# Web
flutter build web --release
```

## 📱 Usage

### Adding an Expense
1. Tap the **+** floating action button on the dashboard
2. Enter the expense amount
3. Select a category from the dropdown
4. Choose the date (defaults to today)
5. Optionally add notes
6. Tap **Add Expense**

### Adding Income or Lend/Borrow
1. Tap the **+** floating action button on the dashboard
2. Choose **Add Income** or **Add Lend/Borrow**
3. Fill required fields (amount + type/person for lend/borrow)
4. Save the entry to update dashboard totals instantly

### Managing Categories
1. Navigate to **Categories** from the dashboard app bar
2. View all existing categories with color indicators
3. Add new categories using the **+** button
4. Edit or delete categories using the menu icon
5. Note: Categories with associated expenses cannot be deleted

### Viewing Analytics
- Dashboard displays live balance from income, expense, borrowed, and lent totals
- Use transaction tabs to filter All, Income, Expense, and Lend/Borrow entries
- Delete entries with confirmation dialogs from list items

## 🔒 Data & Security

- **Local Storage**: All data stored locally using SQLite
- **Soft Deletes**: Deleted records are marked as inactive, preserving data integrity
- **Input Validation**: Comprehensive validation prevents invalid data entry
- **SQL Injection Protection**: Drift ORM provides automatic query parameterization
- **Foreign Key Constraints**: Database-level relationship enforcement

## 🧪 Code Quality

| Metric | Status |
|--------|--------|
| Compilation Errors | ✅ 0 |
| Analysis Warnings | ✅ 0 |
| Deprecated APIs | ✅ 0 |
| Code Style | ✅ Clean |
| Architecture | ✅ MVC with Repository Pattern |

## 🔮 Future Enhancements

- [ ] Edit existing expenses
- [ ] Advanced filtering (date range, category, amount)
- [ ] Search functionality
- [ ] Visual analytics (charts and graphs)
- [ ] Data export (CSV/PDF)
- [ ] Budget tracking and alerts
- [ ] Recurring expenses
- [ ] Cloud backup and sync
- [ ] Receipt image attachments
- [ ] Multi-currency support

## 📄 License

This is a private project developed by **@shahedpy**.

---

<div align="center">

**Built with ❤️ using Flutter**

</div>

