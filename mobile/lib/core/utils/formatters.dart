import 'package:intl/intl.dart';

/// Pure formatting utility helpers. Contains no state or widgets.
abstract final class Formatters {
  static final DateFormat _date = DateFormat.yMMMd();
  static final DateFormat _dateTime = DateFormat.yMMMd().add_jm();
  static final DateFormat _shortDate = DateFormat('d MMM');
  static final DateFormat _timeOnly = DateFormat.jm();

  /// e.g. "Oct 17, 2026"
  static String date(DateTime value) => _date.format(value);

  /// e.g. "17 Oct"
  static String shortDate(DateTime value) => _shortDate.format(value);

  /// e.g. "Oct 17, 2026 11:30 AM"
  static String dateTime(DateTime value) => _dateTime.format(value);

  /// e.g. "11:30 AM"
  static String timeOnly(DateTime value) => _timeOnly.format(value);

  /// Locale-aware integer formatting, e.g. "1,450"
  static String count(int value) => NumberFormat.decimalPattern().format(value);

  /// Elapsed time format as "m:ss", e.g. "2:05"
  static String elapsed(Duration value) {
    final minutes = value.inMinutes;
    final seconds = value.inSeconds - (minutes * 60);
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
