import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task.dart';
import '../utils/helpers.dart';
import 'app_settings.dart';

/// Schedules and cancels task reminders on the device.
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const int _testNowId = 0; // task ids start at 1
  static const int _testScheduledId = 2000000000;

  static const _androidDetails = AndroidNotificationDetails(
    'task_reminders',
    'Task reminders',
    channelDescription: 'Reminders for your tasks',
    importance: Importance.high,
    priority: Priority.high,
    icon: 'ic_stat_taskly',
  );

  static const _details = NotificationDetails(
    android: _androidDetails,
    iOS: DarwinNotificationDetails(),
  );

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    const android = AndroidInitializationSettings('ic_stat_taskly');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _ready = true;
  }

  /// Asks the user for notification permission (only prompts if undecided).
  Future<bool> ensurePermission() async {
    try {
      await init();
      final android = _android;
      if (android != null) {
        return (await android.requestNotificationsPermission()) ?? false;
      }
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      if (ios != null) {
        return (await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            )) ??
            false;
      }
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
    return false;
  }

  /// Android 12+ needs the "Alarms & reminders" permission for on-time alerts.
  Future<bool> canScheduleExact() async {
    try {
      await init();
      final android = _android;
      if (android == null) return true;
      return (await android.canScheduleExactNotifications()) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system page where the user can allow exact alarms.
  Future<void> requestExactPermission() async {
    try {
      await init();
      await _android?.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('Exact alarm permission error: $e');
    }
  }

  Future<AndroidScheduleMode> _mode() async => (await canScheduleExact())
      ? AndroidScheduleMode.exactAllowWhileIdle
      : AndroidScheduleMode.inexactAllowWhileIdle;

  String _body(Task t) {
    final time = fmtTime(t.time);
    final m = t.remindBefore ?? 0;
    if (m == 0) return 'It’s time · $time';
    if (m >= 1440) return 'Tomorrow at $time';
    if (m >= 60) {
      final h = m ~/ 60;
      return 'Starts in ${h == 1 ? '1 hour' : '$h hours'} · $time';
    }
    return 'Starts in $m min · $time';
  }

  /// Schedules (or removes) the reminder for one task.
  /// Returns null on success, or a short error message.
  Future<String?> schedule(Task t) async {
    try {
      await init();
      final wanted =
          settings.remindersEnabled &&
          t.remindBefore != null &&
          t.status != TaskStatus.done;
      if (!wanted) {
        await _plugin.cancel(id: t.id);
        return null;
      }
      final when = t.dueAt.subtract(Duration(minutes: t.remindBefore!));
      if (!when.isAfter(DateTime.now())) {
        await _plugin.cancel(id: t.id);
        return null;
      }
      // Scheduled as an exact moment in time, so it fires correctly
      // whatever the phone's time zone is.
      final at = tz.TZDateTime.from(when, tz.getLocation('UTC'));
      await _plugin.zonedSchedule(
        id: t.id,
        title: t.title,
        body: _body(t),
        scheduledDate: at,
        notificationDetails: _details,
        androidScheduleMode: await _mode(),
      );
      return null;
    } catch (e) {
      debugPrint('Reminder error for task ${t.id}: $e');
      return '$e';
    }
  }

  Future<void> cancel(int id) async {
    try {
      await init();
      await _plugin.cancel(id: id);
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  Future<void> cancelAll() async {
    try {
      await init();
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Cancel-all error: $e');
    }
  }

  /// Shows a notification right now. Returns null on success, else the error.
  Future<String?> showTest() async {
    try {
      await init();
      await _plugin.show(
        id: _testNowId,
        title: 'Reminders are on',
        body: 'You’ll get a notification before your tasks start.',
        notificationDetails: _details,
      );
      return null;
    } catch (e) {
      debugPrint('Test notification error: $e');
      return '$e';
    }
  }

  /// Schedules a notification a few seconds from now (tests the alarm path).
  Future<String?> scheduleTest({int seconds = 10}) async {
    try {
      await init();
      final when = DateTime.now().add(Duration(seconds: seconds));
      await _plugin.zonedSchedule(
        id: _testScheduledId,
        title: 'Scheduled reminders work',
        body: 'This one was set $seconds seconds ago.',
        scheduledDate: tz.TZDateTime.from(when, tz.getLocation('UTC')),
        notificationDetails: _details,
        androidScheduleMode: await _mode(),
      );
      return null;
    } catch (e) {
      debugPrint('Scheduled test error: $e');
      return '$e';
    }
  }
}

final NotificationService notifications = NotificationService();
