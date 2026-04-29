import 'package:intl/intl.dart';

/// Date formatting utilities for Vietnamese locale
class DateFormatters {
  // Vietnam timezone (GMT+7)
  static const Duration vietnamOffset = Duration(hours: 7);

  // Date format for display (DD/MM/YYYY)
  static final DateFormat displayFormat = DateFormat('dd/MM/yyyy');

  // Date format for storage (YYYY-MM-DD)
  static final DateFormat storageFormat = DateFormat('yyyy-MM-dd');

  // Month format for display (MM/YYYY)
  static final DateFormat monthDisplayFormat = DateFormat('MM/yyyy');

  // Month format for storage (YYYY-MM)
  static final DateFormat monthStorageFormat = DateFormat('yyyy-MM');

  // DateTime format for display (DD/MM/YYYY HH:mm)
  static final DateFormat dateTimeFormat = DateFormat('dd/MM/yyyy HH:mm');

  /// Format date for display
  static String formatDate(DateTime date) {
    return displayFormat.format(date);
  }

  /// Format date for storage
  static String formatDateForStorage(DateTime date) {
    return storageFormat.format(date);
  }

  /// Parse date from storage format
  static DateTime? parseDateFromStorage(String dateString) {
    try {
      return storageFormat.parse(dateString);
    } catch (e) {
      return null;
    }
  }

  /// Format month for display
  static String formatMonth(DateTime date) {
    return monthDisplayFormat.format(date);
  }

  /// Format month for storage
  static String formatMonthForStorage(DateTime date) {
    return monthStorageFormat.format(date);
  }

  /// Parse month from storage format
  static DateTime? parseMonthFromStorage(String monthString) {
    try {
      return monthStorageFormat.parse(monthString);
    } catch (e) {
      return null;
    }
  }

  /// Format datetime for display
  static String formatDateTime(DateTime dateTime) {
    return dateTimeFormat.format(dateTime);
  }

  /// Get today's date (Vietnam timezone)
  static DateTime get today {
    final now = DateTime.now().toUtc().add(vietnamOffset);
    return DateTime(now.year, now.month, now.day);
  }

  /// Get first day of month
  static DateTime firstDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month, 1);
  }

  /// Get last day of month
  static DateTime lastDayOfMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0);
  }

  /// Get days in month
  static int daysInMonth(DateTime date) {
    return lastDayOfMonth(date).day;
  }

  /// Check if date is today
  static bool isToday(DateTime date) {
    final today = DateFormatters.today;
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAtSameMomentAs(today);
  }

  /// Check if date is in the past
  static bool isPast(DateTime date) {
    final today = DateFormatters.today;
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isBefore(today);
  }

  /// Check if date is in the future
  static bool isFuture(DateTime date) {
    final today = DateFormatters.today;
    final checkDate = DateTime(date.year, date.month, date.day);
    return checkDate.isAfter(today);
  }

  /// Get month name in Vietnamese
  static String getMonthName(int month) {
    const monthNames = [
      'Tháng 1',
      'Tháng 2',
      'Tháng 3',
      'Tháng 4',
      'Tháng 5',
      'Tháng 6',
      'Tháng 7',
      'Tháng 8',
      'Tháng 9',
      'Tháng 10',
      'Tháng 11',
      'Tháng 12',
    ];
    return monthNames[month - 1];
  }

  /// Get weekday name in Vietnamese
  static String getWeekdayName(DateTime date) {
    const weekdayNames = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];
    return weekdayNames[date.weekday - 1];
  }

  /// Get short weekday name in Vietnamese
  static String getShortWeekdayName(DateTime date) {
    const weekdayNames = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
    return weekdayNames[date.weekday - 1];
  }
}

/// Currency formatting utilities
class CurrencyFormatters {
  // Vietnamese Dong format
  static final NumberFormat vndFormat = NumberFormat.currency(
    locale: 'vi_VN',
    symbol: '₫',
    decimalDigits: 0,
  );

  /// Format currency in Vietnamese Dong
  static String formatVND(double amount) {
    return vndFormat.format(amount);
  }

  /// Parse currency string to double
  static double? parseVND(String currencyString) {
    try {
      // Remove currency symbol and spaces
      final cleanString = currencyString.replaceAll('₫', '').replaceAll(' ', '').trim();
      return double.parse(cleanString);
    } catch (e) {
      return null;
    }
  }
}

/// Validation utilities
class ValidationUtils {
  /// Validate Vietnamese phone number
  static bool isValidPhoneNumber(String phone) {
    if (phone.trim().isEmpty) return false; // Phone is optional
    final phoneRegex = RegExp(r'^0\d{9,10}$');
    return phoneRegex.hasMatch(phone.trim());
  }

  /// Validate employee name
  static bool isValidEmployeeName(String name) {
    if (name.trim().isEmpty) return false;
    if (name.trim().length < 2) return false;
    if (name.trim().length > 50) return false;
    return true;
  }

  /// Validate daily rate
  static bool isValidDailyRate(double rate) {
    return rate >= 0 && rate <= 100000000;
  }

  /// Validate night rate multiplier
  static bool isValidNightRateMultiplier(double multiplier) {
    return multiplier >= 1.0 && multiplier <= 3.0;
  }

  /// Validate month format (YYYY-MM)
  static bool isValidMonthFormat(String month) {
    final regex = RegExp(r'^\d{4}-\d{2}$');
    if (!regex.hasMatch(month)) return false;

    final parts = month.split('-');
    final year = int.parse(parts[0]);
    final monthNum = int.parse(parts[1]);

    return year >= 1900 && year <= 2100 && monthNum >= 1 && monthNum <= 12;
  }
}
