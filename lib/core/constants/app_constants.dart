class AppConstants {
  // Currency
  static const String currencySymbol = '৳';
  static const String currencyCode = 'BDT';

  // Date formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String dateTimeFormat = 'dd MMM yyyy hh:mm a';
  static const String timeFormat = 'hh:mm a';

  // Default categories
  static const List<Map<String, dynamic>> defaultCategories = [
    {'name': 'Food', 'color': 0xFFFF6B6B},
    {'name': 'Transport', 'color': 0xFF4ECDC4},
    {'name': 'Entertainment', 'color': 0xFF45B7D1},
    {'name': 'Shopping', 'color': 0xFFFFA07A},
    {'name': 'Bills', 'color': 0xFF98D8C8},
    {'name': 'Health', 'color': 0xFFF7DC6F},
    {'name': 'Other', 'color': 0xFFBB86FC},
  ];

  static const List<Map<String, dynamic>> defaultIncomeSources = [
    {'name': 'Salary', 'color': 0xFF4CAF50},
    {'name': 'Freelance', 'color': 0xFF00BCD4},
    {'name': 'Business', 'color': 0xFF3F51B5},
    {'name': 'Bonus', 'color': 0xFFFFC107},
    {'name': 'Interest', 'color': 0xFF009688},
    {'name': 'Gift', 'color': 0xFFE91E63},
    {'name': 'Other', 'color': 0xFF9C27B0},
  ];

  // Validation
  static const double minExpenseAmount = 0.01;
  static const double maxExpenseAmount = 999999.99;
  static const int maxNoteLength = 500;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultBorderRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
}
