import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';
import '../utils/helpers.dart';
import 'notification_service.dart';

/// Holds all tasks, saves them on the device and keeps reminders in sync.
class TaskStore extends ChangeNotifier {
  final List<Task> _tasks = [];
  int _nextId = 1;
  SharedPreferences? _prefs;

  bool get hasAny => _tasks.isNotEmpty;
  int get completedCount =>
      _tasks.where((t) => t.status == TaskStatus.done).length;

  Future<void> load() async {
    final p = _prefs = await SharedPreferences.getInstance();
    final raw = p.getString('tasks');
    if (raw != null) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Task.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _tasks
          ..clear()
          ..addAll(list);
        _nextId = _tasks.fold<int>(0, (max, t) => t.id > max ? t.id : max) + 1;
      } catch (_) {
        _tasks.clear();
      }
    }
    notifyListeners();
  }

  void _persist() {
    _prefs?.setString(
      'tasks',
      jsonEncode(_tasks.map((t) => t.toJson()).toList()),
    );
  }

  List<Task> forDate(DateTime d) {
    final list = _tasks.where((t) => isSameDay(t.date, d)).toList()
      ..sort((a, b) => a.minutes.compareTo(b.minutes));
    return list;
  }

  int countInMonth(DateTime d) => _tasks
      .where((t) => t.date.year == d.year && t.date.month == d.month)
      .length;

  void add(
    String title,
    String description,
    DateTime date,
    TimeOfDay time, {
    double progress = 0,
    int? remindBefore,
  }) {
    final task = Task(
      id: _nextId++,
      title: title,
      description: description,
      date: DateTime(date.year, date.month, date.day),
      time: time,
      progress: progress,
      remindBefore: remindBefore,
    );
    _tasks.add(task);
    _persist();
    unawaited(notifications.schedule(task));
    notifyListeners();
  }

  /// To-Do → In progress (50%) → Done → back to To-Do
  void cycle(Task t) {
    switch (t.status) {
      case TaskStatus.todo:
        t.progress = 0.5;
        break;
      case TaskStatus.progress:
        t.progress = 1;
        break;
      case TaskStatus.done:
        t.progress = 0;
        break;
    }
    _persist();
    // Completed tasks lose their reminder; reopened ones get it back.
    unawaited(notifications.schedule(t));
    notifyListeners();
  }

  void remove(Task t) {
    _tasks.removeWhere((x) => x.id == t.id);
    _persist();
    unawaited(notifications.cancel(t.id));
    notifyListeners();
  }

  void clearCompleted() {
    final done = _tasks.where((t) => t.status == TaskStatus.done).toList();
    _tasks.removeWhere((t) => t.status == TaskStatus.done);
    _persist();
    for (final t in done) {
      unawaited(notifications.cancel(t.id));
    }
    notifyListeners();
  }

  void clearAll() {
    _tasks.clear();
    _persist();
    unawaited(notifications.cancelAll());
    notifyListeners();
  }

  /// Rebuilds every pending reminder (used at app start and when the
  /// reminders switch changes).
  Future<void> rescheduleReminders() async {
    await notifications.cancelAll();
    for (final t in List<Task>.of(_tasks)) {
      await notifications.schedule(t);
    }
  }
}

/// App-wide instance used by the screens.
final TaskStore store = TaskStore();
