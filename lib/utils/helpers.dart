import 'package:flutter/material.dart';

import '../services/app_settings.dart';

const weekdayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _monthShort = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

/// Respects the 12/24-hour setting.
String fmtTime(TimeOfDay t) {
  final m = t.minute.toString().padLeft(2, '0');
  if (settings.use24h) {
    return '${t.hour.toString().padLeft(2, '0')}:$m';
  }
  final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
  return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
}

String fmtDate(DateTime d) =>
    '${weekdayShort[d.weekday - 1]}, ${d.day} ${_monthShort[d.month - 1]}';

String greeting() {
  final h = DateTime.now().hour;
  final base = h < 12
      ? 'Good Morning'
      : h < 17
      ? 'Good Afternoon'
      : 'Good Evening';
  final name = settings.userName.trim();
  return name.isEmpty ? '$base!' : '$base, $name!';
}

/// "Today · Sun, 1 Nov", "Tomorrow · Mon, 2 Nov", or "Fri, 14 Nov" (+ year if not this year).
String friendlyDate(DateTime d) {
  final now = DateTime.now();
  final today = DateTime.utc(now.year, now.month, now.day);
  final day = DateTime.utc(d.year, d.month, d.day);
  final diff = day.difference(today).inDays;
  final base = fmtDate(d);
  if (diff == 0) return 'Today · $base';
  if (diff == 1) return 'Tomorrow · $base';
  return d.year == now.year ? base : '$base ${d.year}';
}
