import 'package:flutter/material.dart';

enum TaskStatus { todo, progress, done }

class Task {
  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    this.progress = 0,
    this.remindBefore,
  });

  final int id;
  String title;
  String description;
  DateTime date;
  TimeOfDay time;
  double progress; // 0.0 → 1.0

  /// Minutes before the task time to send a reminder.
  /// null = no reminder, 0 = at the task time.
  int? remindBefore;

  TaskStatus get status {
    if (progress >= 1) return TaskStatus.done;
    if (progress > 0) return TaskStatus.progress;
    return TaskStatus.todo;
  }

  int get minutes => time.hour * 60 + time.minute;

  /// The exact moment the task starts.
  DateTime get dueAt =>
      DateTime(date.year, date.month, date.day, time.hour, time.minute);

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'date':
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
    'minutes': minutes,
    'progress': progress,
    'remind': remindBefore,
  };

  factory Task.fromJson(Map<String, dynamic> j) {
    final d = DateTime.parse(j['date'] as String);
    final m = j['minutes'] as int;
    return Task(
      id: j['id'] as int,
      title: j['title'] as String,
      description: j['description'] as String,
      date: DateTime(d.year, d.month, d.day),
      time: TimeOfDay(hour: m ~/ 60, minute: m % 60),
      progress: (j['progress'] as num).toDouble(),
      remindBefore: j['remind'] as int?,
    );
  }
}
