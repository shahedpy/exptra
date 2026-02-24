import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_constants.dart';

class DateHelper {
  static String formatDate(DateTime date) {
    return DateFormat(AppConstants.dateFormat).format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat(AppConstants.dateTimeFormat).format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat(AppConstants.timeFormat).format(date);
  }

  static String formatDateShort(DateTime date) {
    return DateFormat('dd MMM').format(date);
  }

  static String formatMonthYear(DateTime date) {
    return DateFormat('MMM yyyy').format(date);
  }

  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  static String getRelativeDate(DateTime date) {
    if (isToday(date)) {
      return 'Today';
    } else if (isYesterday(date)) {
      return 'Yesterday';
    } else {
      return formatDate(date);
    }
  }
}

class CurrencyHelper {
  static final NumberFormat _bdNumberFormat = NumberFormat(
    '#,##,##0.00',
    'en_BD',
  );

  static String formatAmount(double amount) {
    return '${AppConstants.currencySymbol}${_bdNumberFormat.format(amount)}';
  }

  static String formatAmountCompact(double amount) {
    if (amount >= 1000000) {
      return '${AppConstants.currencySymbol}${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${AppConstants.currencySymbol}${(amount / 1000).toStringAsFixed(1)}K';
    }
    return formatAmount(amount);
  }

  static double parseAmount(String amount) {
    try {
      final normalized = amount
          .replaceAll(AppConstants.currencySymbol, '')
          .replaceAll(',', '')
          .trim();
      return double.parse(normalized);
    } catch (e) {
      return 0.0;
    }
  }
}

class ColorHelper {
  static Color getColorFromInt(int? colorInt) {
    if (colorInt == null) {
      return Colors.grey;
    }
    return Color(colorInt);
  }

  static int getColorAsInt(Color color) {
    return color.toARGB32();
  }

  static List<Color> getCategoryColors() {
    return AppConstants.defaultCategories
        .map((cat) => Color(cat['color'] as int))
        .toList();
  }

  static Color getContrastColor(Color color) {
    // Calculate luminance
    final r = (color.r * 255.0).round();
    final g = (color.g * 255.0).round();
    final b = (color.b * 255.0).round();
    final luminance = (0.299 * r + 0.587 * g + 0.114 * b) / 255;
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class ValidationHelper {
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }

    final normalized = value
        .replaceAll(AppConstants.currencySymbol, '')
        .replaceAll(',', '')
        .trim();

    final amount = double.tryParse(normalized);
    if (amount == null) {
      return 'Invalid amount';
    }

    if (amount < AppConstants.minExpenseAmount) {
      return 'Amount must be at least ${AppConstants.currencySymbol}0.01';
    }

    if (amount > AppConstants.maxExpenseAmount) {
      return 'Amount is too large';
    }

    return null;
  }

  static String? validateNote(String? value) {
    if (value != null && value.length > AppConstants.maxNoteLength) {
      return 'Note cannot exceed ${AppConstants.maxNoteLength} characters';
    }
    return null;
  }

  static String? validateCategoryName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Category name is required';
    }
    if (value.length < 2) {
      return 'Category name must be at least 2 characters';
    }
    if (value.length > 50) {
      return 'Category name cannot exceed 50 characters';
    }
    return null;
  }
}
