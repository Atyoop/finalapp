import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Helper functions for time formatting and parsing

/// Format TimeOfDay to display string: "8:00 AM"
String formatTimeOfDayForDisplay(TimeOfDay time) {
  final hour = time.hour;
  final minute = time.minute.toString().padLeft(2, '0');
  final period = hour >= 12 ? 'PM' : 'AM';
  final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
  return '$displayHour:$minute $period';
}

/// Convert TimeOfDay to API format: "HH:mm:ss"
String formatTimeOfDayForApi(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
}

/// Parse API time string "HH:mm:ss" to TimeOfDay
TimeOfDay parseApiTimeToTimeOfDay(String value) {
  try {
    final parts = value.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }
  } catch (_) {}
  return const TimeOfDay(hour: 9, minute: 0);
}

/// Format API time "HH:mm:ss" for display: "8:00 AM"
String formatApiTimeForDisplay(String value) {
  try {
    final timeOfDay = parseApiTimeToTimeOfDay(value);
    final hour = timeOfDay.hour;
    final minute = timeOfDay.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  } catch (_) {
    return value;
  }
}

/// Normalize dose times: remove duplicates, sort, convert to a string list.
/// Never returns [""] or list with empty strings
List<String> normalizeDoseTimesBeforeSave(List<TimeOfDay> times) {
  // Remove duplicates
  final uniqueTimes = <TimeOfDay>{};
  for (final t in times) {
    uniqueTimes.add(t);
  }

  // Sort ascending
  final sortedTimes = uniqueTimes.toList()
    ..sort((a, b) {
      final aMinutes = a.hour * 60 + a.minute;
      final bMinutes = b.hour * 60 + b.minute;
      return aMinutes.compareTo(bMinutes);
    });

  // Convert to List<String>
  final result = sortedTimes.map(formatTimeOfDayForApi).toList();

  // Ensure we never return [""] or empty strings
  return result.where((t) => t.trim().isNotEmpty).toList();
}

/// Build schedule summary for display in My Meds card
/// Example: "Every 6 hours - starts 8:00 AM"
/// Example: "3 times per day - 3:00 AM, 8:00 AM, 10:00 AM"
String buildScheduleSummary(dynamic medicine, {String locale = 'en'}) {
  final isAr = locale == 'ar';
  final scheduleType = medicine.scheduleType as String?;
  final intervalHours = medicine.intervalHours as int?;
  final doseTimes = medicine.doseTimes as List<String>?;
  final dosesPerPeriod = medicine.dosesPerPeriod as int?;
  final timeOfDay = medicine.time as TimeOfDay?;

  // If scheduleType is set
  if (scheduleType == 'Interval' && intervalHours != null) {
    final firstTime = timeOfDay != null
        ? formatTimeOfDayForDisplay(timeOfDay)
        : 'N/A';
    return isAr
        ? 'كل $intervalHours ساعات - يبدأ $firstTime'
        : 'Every $intervalHours hours - starts $firstTime';
  }

  if (scheduleType == 'CustomTimes' &&
      doseTimes != null &&
      doseTimes.isNotEmpty) {
    final timeStrings = doseTimes
        .map((t) => formatApiTimeForDisplay(t))
        .toList();
    return isAr
        ? '${doseTimes.length} مرات يوميا - ${timeStrings.join(', ')}'
        : '${doseTimes.length} times per day - ${timeStrings.join(', ')}';
  }

  // Fallback logic
  if (intervalHours != null && intervalHours > 0) {
    final firstTime = timeOfDay != null
        ? formatTimeOfDayForDisplay(timeOfDay)
        : 'N/A';
    return isAr
        ? 'كل $intervalHours ساعات - يبدأ $firstTime'
        : 'Every $intervalHours hours - starts $firstTime';
  }

  if (doseTimes != null && doseTimes.isNotEmpty) {
    final timeStrings = doseTimes
        .map((t) => formatApiTimeForDisplay(t))
        .toList();
    return isAr
        ? '${doseTimes.length} مرات يوميا - ${timeStrings.join(', ')}'
        : '${doseTimes.length} times per day - ${timeStrings.join(', ')}';
  }

  if (dosesPerPeriod != null && dosesPerPeriod > 0) {
    return isAr
        ? '$dosesPerPeriod مرات يوميا'
        : '$dosesPerPeriod times per day';
  }

  return isAr ? 'لم يتم ضبط الجدول' : 'Schedule not set';
}

/// Parse doseTimes from JSON, ensuring a string list type.
/// Example: "doseTimes": ["03:00:00", "08:00:00", "10:00:00"]
List<String> parseDoseTimesFromJson(dynamic jsonValue) {
  final doseTimes =
      (jsonValue as List?)
          ?.map((e) => e.toString())
          .where((e) => e.trim().isNotEmpty)
          .toList() ??
      <String>[];
  return doseTimes;
}

/// Format remaining pills for display
String formatRemainingPills(int? currentPillCount, {String locale = 'en'}) {
  if (currentPillCount == null) {
    return locale == 'ar' ? 'لم يتم تحديد المخزون' : 'Stock not set';
  }
  return locale == 'ar'
      ? 'المتبقي: $currentPillCount'
      : '$currentPillCount pills remaining';
}

/// Format expiry date for display
String formatExpiryDate(DateTime? expiryDate, {String locale = 'en'}) {
  if (expiryDate == null) {
    return '';
  }
  final formatted = DateFormat('MMM d, yyyy', locale).format(expiryDate);
  return locale == 'ar' ? 'ينتهي: $formatted' : 'Expires: $formatted';
}
