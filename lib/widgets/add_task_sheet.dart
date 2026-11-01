import 'package:flutter/material.dart';

import '../services/app_settings.dart';
import '../services/notification_service.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../utils/helpers.dart';

/// Opens the "New task" sheet. Returns the date the task was saved on,
/// or null if the sheet was closed without saving.
Future<DateTime?> showAddTaskSheet(BuildContext context, DateTime date) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: context.pal.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => AddTaskSheet(date: date),
  );
}

class AddTaskSheet extends StatefulWidget {
  const AddTaskSheet({super.key, required this.date});
  final DateTime date;

  @override
  State<AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<AddTaskSheet> {
  final _title = TextEditingController();
  final _desc = TextEditingController();
  late DateTime _date = DateTime(
    widget.date.year,
    widget.date.month,
    widget.date.day,
  );
  TimeOfDay _time = TimeOfDay.now();
  bool _calendarOpen = false;
  int? _remind = 0; // minutes before; null = no reminder
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx)
            .copyWith(alwaysUse24HourFormat: settings.use24h),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      setState(() => _error = 'Give your task a title');
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    String? message;

    // Ask for notification permission the first time a reminder is used.
    if (_remind != null) {
      if (!settings.remindersEnabled) {
        message = 'Reminders are turned off in Settings';
      } else {
        final allowed = await notifications.ensurePermission();
        if (!allowed) {
          message =
              'Allow notifications in your phone settings to get reminders';
        }
      }
    }
    if (!mounted) return;

    store.add(
      _title.text.trim(),
      _desc.text.trim(),
      _date,
      _time,
      remindBefore: _remind,
    );

    message ??= isSameDay(_date, DateTime.now())
        ? null
        : 'Task added for ${fmtDate(_date)}';
    if (message != null) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
        );
    }
    navigator.pop(_date);
  }

  InputDecoration _decoration(Palette pal, String hint, {String? error}) =>
      InputDecoration(
        hintText: hint,
        errorText: error,
        hintStyle: TextStyle(color: pal.muted),
        filled: true,
        fillColor: pal.field,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      );

  Widget _pickerRow({
    required Palette pal,
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: pal.field,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(icon, color: pal.muted, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: TextStyle(color: pal.ink, fontWeight: FontWeight.w600),
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: pal.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'New task',
            style: TextStyle(
              color: pal.ink,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _title,
            style: TextStyle(color: pal.ink),
            textCapitalization: TextCapitalization.sentences,
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            decoration: _decoration(pal, 'Title', error: _error),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _desc,
            style: TextStyle(color: pal.ink),
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: _decoration(pal, 'Description (optional)'),
          ),
          const SizedBox(height: 12),

          // Date row — tap to expand the calendar
          _pickerRow(
            pal: pal,
            icon: Icons.calendar_month_rounded,
            text: friendlyDate(_date),
            onTap: () {
              FocusScope.of(context).unfocus();
              setState(() => _calendarOpen = !_calendarOpen);
            },
            trailing: AnimatedRotation(
              turns: _calendarOpen ? 0.5 : 0,
              duration: const Duration(milliseconds: 200),
              child: Icon(Icons.expand_more_rounded, color: pal.muted),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: _calendarOpen
                ? Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: pal.field,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: CalendarDatePicker(
                        initialDate: _date,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        onDateChanged: (d) => setState(
                          () => _date = DateTime(d.year, d.month, d.day),
                        ),
                      ),
                    ),
                  )
                : const SizedBox(width: double.infinity, height: 0),
          ),
          const SizedBox(height: 12),

          // Time row
          _pickerRow(
            pal: pal,
            icon: Icons.schedule_rounded,
            text: fmtTime(_time),
            onTap: _pickTime,
          ),
          const SizedBox(height: 18),

          // Reminder
          Row(
            children: [
              Icon(
                Icons.notifications_active_outlined,
                size: 18,
                color: pal.muted,
              ),
              const SizedBox(width: 8),
              Text(
                'Remind me',
                style: TextStyle(
                  color: pal.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final o in reminderOptions)
                _RemindChip(
                  label: o.$2,
                  selected: _remind == o.$1,
                  onTap: () => setState(() => _remind = o.$1),
                ),
            ],
          ),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text(
                'Save task',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RemindChip extends StatelessWidget {
  const _RemindChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withAlpha(28) : pal.field,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.blue : pal.ink,
          ),
        ),
      ),
    );
  }
}
