class MedicationTimeService {
  static List<String> generateMedicationTimes({
    required String firstReminderTime,
    required int timesPerDay,
  }) {
    final firstTime = firstReminderTime.trim();
    final startMinutes = parseTimeToMinutes(firstTime);

    if (startMinutes == null || timesPerDay <= 1) {
      return [formatTimeForDisplay(firstTime)];
    }

    final intervalMinutes = (24 * 60) ~/ timesPerDay;
    final List<String> times = [];

    for (int index = 0; index < timesPerDay; index++) {
      final totalMinutes =
          (startMinutes + (index * intervalMinutes)) % (24 * 60);

      times.add(formatMinutesToArabicTime(totalMinutes));
    }

    return times;
  }

  static int? parseTimeToMinutes(String value) {
    final trimmed = value.trim();

    final arabicMatch =
        RegExp(r'(\d{1,2}):(\d{2})\s*([صم])').firstMatch(trimmed);

    if (arabicMatch != null) {
      int hour = int.parse(arabicMatch.group(1)!);
      final minute = int.parse(arabicMatch.group(2)!);
      final period = arabicMatch.group(3)!;

      if (period == 'م' && hour != 12) hour += 12;
      if (period == 'ص' && hour == 12) hour = 0;

      return (hour * 60) + minute;
    }

    final dbMatch = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(trimmed);

    if (dbMatch != null) {
      final hour = int.parse(dbMatch.group(1)!);
      final minute = int.parse(dbMatch.group(2)!);

      return (hour * 60) + minute;
    }

    return null;
  }

  static String formatMinutesToArabicTime(int totalMinutes) {
    final hour24 = totalMinutes ~/ 60;
    final minute = totalMinutes % 60;

    final period = hour24 >= 12 ? 'م' : 'ص';

    int hour12 = hour24 % 12;
    if (hour12 == 0) {
      hour12 = 12;
    }

    final minuteText = minute.toString().padLeft(2, '0');

    return '$hour12:$minuteText $period';
  }

  static String formatTimeForDisplay(String value) {
    final minutes = parseTimeToMinutes(value);

    if (minutes == null) {
      return value;
    }

    return formatMinutesToArabicTime(minutes);
  }
}
