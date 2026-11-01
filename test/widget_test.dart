import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:todo_app/models/task.dart';

void main() {
  test('Task status follows progress', () {
    final task = Task(
      id: 1,
      title: 'Test',
      description: '',
      date: DateTime(2026, 11, 1),
      time: const TimeOfDay(hour: 9, minute: 0),
    );

    expect(task.status, TaskStatus.todo);
    task.progress = 0.5;
    expect(task.status, TaskStatus.progress);
    task.progress = 1;
    expect(task.status, TaskStatus.done);
  });
}
