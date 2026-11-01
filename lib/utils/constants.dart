const String appName = 'Taskly';
const String appVersion = '1.0.0';
const String appTagline = 'Plan your day, one task at a time';

/// Reminder choices shown when adding a task: (minutes before, label).
/// null = no reminder, 0 = at the task time.
const List<(int?, String)> reminderOptions = [
  (null, 'None'),
  (0, 'At time'),
  (10, '10 min before'),
  (30, '30 min before'),
  (60, '1 hour before'),
  (1440, '1 day before'),
];
