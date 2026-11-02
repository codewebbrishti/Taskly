import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/app_settings.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';
import '../widgets/add_task_sheet.dart';
import '../widgets/category_chip.dart';
import '../widgets/empty_state.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/responsive_safe_area.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/today_card.dart';
import 'schedule_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String query = '';
  TaskStatus? filter;

  static const _cardColors = [
    AppColors.blue,
    AppColors.red,
    AppColors.amber,
    AppColors.green,
  ];

  void _openSchedule() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SchedulePage(initialDate: DateTime.now()),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SettingsPage()));
  }

  void _addTask() => showAddTaskSheet(context, DateTime.now());

  void _toggleFilter(TaskStatus status) {
    setState(() => filter = filter == status ? null : status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveSafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([store, settings]),
          builder: (context, _) {
            final pal = context.pal;
            final now = DateTime.now();
            final todayAll = store.forDate(now);
            final q = query.trim().toLowerCase();
            final tasks = todayAll.where((t) {
              final matchesQuery = t.title.toLowerCase().contains(q);
              final matchesFilter = filter == null || t.status == filter;
              return matchesQuery && matchesFilter;
            }).toList();

            final monthCount = store.countInMonth(now);
            final countLabel = monthCount == 0
                ? 'no tasks'
                : monthCount == 1
                ? '1 task'
                : '$monthCount tasks';

            return ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      RoundIconButton(
                        icon: Icons.calendar_month_rounded,
                        onTap: _openSchedule,
                      ),
                      GestureDetector(
                        onTap: _openSettings,
                        child: ProfileAvatar(
                          name: settings.userName,
                          imagePath: settings.profileImagePath,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),

                // Greeting
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting(),
                        style: TextStyle(color: pal.muted, fontSize: 14),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: TextStyle(
                            color: pal.ink,
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                          children: [
                            const TextSpan(text: 'You have '),
                            TextSpan(
                              text: countLabel,
                              style: const TextStyle(color: AppColors.blue),
                            ),
                            const TextSpan(text: '\nthis month 👍'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Search
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: TextField(
                    onChanged: (v) => setState(() => query = v),
                    style: TextStyle(color: pal.ink),
                    decoration: InputDecoration(
                      hintText: 'Search a task....',
                      hintStyle: TextStyle(color: pal.muted),
                      prefixIcon: Icon(Icons.search_rounded, color: pal.muted),
                      filled: true,
                      fillColor: pal.field,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Categories
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    spacing: 12,
                    children: [
                      CategoryChip(
                        label: 'To-Do',
                        icon: Icons.assignment_outlined,
                        color: AppColors.red,
                        selected: filter == TaskStatus.todo,
                        onTap: () => _toggleFilter(TaskStatus.todo),
                      ),
                      CategoryChip(
                        label: 'Progress',
                        icon: Icons.timelapse_rounded,
                        color: AppColors.amber,
                        selected: filter == TaskStatus.progress,
                        onTap: () => _toggleFilter(TaskStatus.progress),
                      ),
                      CategoryChip(
                        label: 'Done',
                        icon: Icons.assignment_turned_in_outlined,
                        color: AppColors.green,
                        selected: filter == TaskStatus.done,
                        onTap: () => _toggleFilter(TaskStatus.done),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Section header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Today’s Tasks',
                        style: TextStyle(
                          color: pal.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _openSchedule,
                            child: Text(
                              'See All',
                              style: TextStyle(color: pal.muted, fontSize: 13),
                            ),
                          ),
                          const SizedBox(width: 14),
                          GestureDetector(
                            onTap: _addTask,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: AppColors.blue,
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(
                                Icons.add_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Content
                if (todayAll.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: EmptyState(
                      icon: Icons.checklist_rounded,
                      title: store.hasAny
                          ? 'Nothing planned today'
                          : 'No tasks yet',
                      message: store.hasAny
                          ? 'Add a task for today, or open See All to plan another day.'
                          : 'Add your first task and it will show up here.',
                      actionLabel: 'Add task',
                      onAction: _addTask,
                    ),
                  )
                else if (tasks.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 24,
                    ),
                    child: Text(
                      'No tasks match your search or filter.',
                      style: TextStyle(color: pal.muted),
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      children: [
                        for (var i = 0; i < tasks.length; i++) ...[
                          if (i > 0) const SizedBox(height: 14),
                          TodayCard(
                            task: tasks[i],
                            color: _cardColors[i % _cardColors.length],
                            onTap: _openSchedule,
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
