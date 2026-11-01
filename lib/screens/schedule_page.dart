import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/app_settings.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/empty_state.dart';
import '../widgets/responsive_safe_area.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/timeline_row.dart';

class SchedulePage extends StatefulWidget {
  const SchedulePage({super.key, required this.initialDate});
  final DateTime initialDate;

  @override
  State<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends State<SchedulePage> {
  late DateTime selected = widget.initialDate;

  Future<void> _addTask() async {
    final saved = await showAddTaskSheet(context, selected);
    if (saved != null && mounted) setState(() => selected = saved);
  }

  /// The 7 days of the week containing [selected], honouring the
  /// "week starts on" setting.
  List<DateTime> get _week {
    final offset = settings.weekStartsMonday
        ? selected.weekday - 1
        : selected.weekday % 7;
    final start = DateTime(
      selected.year,
      selected.month,
      selected.day - offset,
    );
    return List.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveSafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([store, settings]),
          builder: (context, _) {
            final pal = context.pal;
            final tasks = store.forDate(selected);
            final activeIndex = tasks.indexWhere(
              (t) => t.status != TaskStatus.done,
            );

            return Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_rounded,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addTask,
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: const Text(
                          'Add Task',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.blue,
                          foregroundColor: Colors.white,
                          elevation: 6,
                          shadowColor: AppColors.blue.withAlpha(120),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 22,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),

                  // Week strip
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: _week.map((d) {
                      final isSel = isSameDay(d, selected);
                      final color = isSel ? AppColors.blue : pal.muted;
                      final weight = isSel ? FontWeight.w800 : FontWeight.w500;
                      return Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => setState(() => selected = d),
                          child: SizedBox(
                            width: 40,
                            child: Column(
                              children: [
                                Text(
                                  weekdayShort[d.weekday - 1],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: color,
                                    fontWeight: weight,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${d.day}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: color,
                                    fontWeight: weight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  width: 4,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSel
                                        ? AppColors.blue
                                        : Colors.transparent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 18),

                  // Timeline
                  Expanded(
                    child: tasks.isEmpty
                        ? Align(
                            alignment: Alignment.topCenter,
                            child: Padding(
                              padding: const EdgeInsets.only(top: 16),
                              child: EmptyState(
                                icon: Icons.event_available_rounded,
                                title: 'Nothing planned',
                                message: 'Add a task for ${fmtDate(selected)}.',
                                actionLabel: 'Add task',
                                onAction: _addTask,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: tasks.length,
                            itemBuilder: (_, i) {
                              final t = tasks[i];
                              return TimelineRow(
                                key: ValueKey(t.id),
                                task: t,
                                isActive: i == activeIndex,
                                isLast: i == tasks.length - 1,
                                pastel: pal.pastels[i % pal.pastels.length],
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
