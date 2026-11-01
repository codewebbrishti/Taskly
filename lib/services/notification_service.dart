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
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
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
    } catch (_) {}
    return false;
  }

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
  Future<void> schedule(Task t) async {
    try {
      await init();
      final wanted =
          settings.remindersEnabled &&
          t.remindBefore != null &&
          t.status != TaskStatus.done;
      if (!wanted) {
        await _plugin.cancel(id: t.id);
        return;
      }
      final when = t.dueAt.subtract(Duration(minutes: t.remindBefore!));
      if (!when.isAfter(DateTime.now())) {
        await _plugin.cancel(id: t.id);
        return;
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
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    try {
      await init();
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> cancelAll() async {
    try {
      await init();
      await _plugin.cancelAll();
    } catch (_) {}
  }

  Future<void> showTest() async {
    try {
      await init();
      await _plugin.show(
        id: 0,
        title: 'Reminders are on',
        body: 'You’ll get a notification before your tasks start.',
        notificationDetails: _details,
      );
    } catch (_) {}
  }
}

final NotificationService notifications = NotificationService();
