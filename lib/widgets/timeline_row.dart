import 'package:flutter/material.dart';

import '../models/task.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/helpers.dart';

class TimelineRow extends StatelessWidget {
  const TimelineRow({
    super.key,
    required this.task,
    required this.isActive,
    required this.isLast,
    required this.pastel,
  });

  final Task task;
  final bool isActive;
  final bool isLast;
  final Color pastel;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final done = task.status == TaskStatus.done;
    final bg = isActive ? AppColors.red : pastel;
    final titleColor = isActive ? Colors.white : pal.ink;
    final bodyColor = isActive ? Colors.white.withAlpha(200) : pal.muted;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline rail
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const SizedBox(height: 18),
                isActive
                    ? Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.red, width: 2.5),
                        ),
                        child: Center(
                          child: Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.red,
                            ),
                          ),
                        ),
                      )
                    : Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? AppColors.red : pal.bg,
                          border: Border.all(color: AppColors.red, width: 2),
                        ),
                      ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.red)),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Dismissible(
                  key: ValueKey('dismiss-${task.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(
                      Icons.delete_outline_rounded,
                      color: Colors.white,
                    ),
                  ),
                  onDismissed: (_) => store.remove(task),
                  child: Material(
                    color: bg,
                    child: InkWell(
                      onTap: () => store.cycle(task),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    task.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: titleColor,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      decoration: done
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (task.status != TaskStatus.todo)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: Icon(
                                      done
                                          ? Icons.check_circle_rounded
                                          : Icons.timelapse_rounded,
                                      size: 16,
                                      color: isActive
                                          ? Colors.white
                                          : (done
                                                ? AppColors.green
                                                : AppColors.amber),
                                    ),
                                  ),
                                Text(
                                  fmtTime(task.time),
                                  style: TextStyle(
                                    color: titleColor,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (done) ...[
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => store.remove(task),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 20,
                                      color: AppColors.red,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (task.description.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                task.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: bodyColor,
                                  fontSize: 12.5,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
