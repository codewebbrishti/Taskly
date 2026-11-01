import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/app_settings.dart';
import '../services/notification_service.dart';
import '../services/task_store.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';
import '../widgets/profile_avatar.dart';
import '../widgets/responsive_safe_area.dart';
import '../widgets/round_icon_button.dart';
import '../widgets/settings_tiles.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  Future<bool> _confirm(
    BuildContext context, {
    required String title,
    required String message,
    required String action,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.red),
            child: Text(action),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _editName(BuildContext context) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: settings.userName),
    );
    if (name != null) settings.setUserName(name.trim());
  }

  Future<void> _toggleReminders(BuildContext context, bool on) async {
    if (on) {
      final allowed = await notifications.ensurePermission();
      settings.setRemindersEnabled(true);
      await store.rescheduleReminders();
      if (!allowed && context.mounted) {
        _snack(
          context,
          'Allow notifications for $appName in your phone settings',
        );
      }
    } else {
      settings.setRemindersEnabled(false);
      await notifications.cancelAll();
    }
  }

  Future<void> _testNotification(BuildContext context) async {
    final allowed = await notifications.ensurePermission();
    if (!context.mounted) return;
    if (!allowed) {
      _snack(
        context,
        'Allow notifications for $appName in your phone settings',
      );
      return;
    }
    await notifications.showTest();
    if (!context.mounted) return;
    _snack(context, 'Test notification sent');
  }

  Future<void> _clearCompleted(BuildContext context) async {
    if (store.completedCount == 0) {
      _snack(context, 'No completed tasks to clear');
      return;
    }
    final ok = await _confirm(
      context,
      title: 'Clear completed tasks?',
      message:
          'This removes ${store.completedCount} completed task(s). It can’t be undone.',
      action: 'Clear',
    );
    if (!ok || !context.mounted) return;
    store.clearCompleted();
    _snack(context, 'Completed tasks cleared');
  }

  Future<void> _deleteAll(BuildContext context) async {
    if (!store.hasAny) {
      _snack(context, 'You don’t have any tasks yet');
      return;
    }
    final ok = await _confirm(
      context,
      title: 'Delete all tasks?',
      message:
          'Every task will be removed from this device. It can’t be undone.',
      action: 'Delete all',
    );
    if (!ok || !context.mounted) return;
    store.clearAll();
    _snack(context, 'All tasks deleted');
  }

  void _showHelp(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How it works'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• Tap + to add a task for a day.'),
            SizedBox(height: 8),
            Text(
              '• Open See All, then pick a day in the week strip to plan ahead.',
            ),
            SizedBox(height: 8),
            Text('• Tap a task to move it from To-Do to In progress to Done.'),
            SizedBox(height: 8),
            Text('• Swipe a task left to delete it.'),
            SizedBox(height: 8),
            Text(
              '• Use the circles on the home screen to filter today’s tasks.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: appName,
      applicationVersion: appVersion,
      applicationIcon: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.blue,
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.check_rounded, color: Colors.white, size: 30),
      ),
      children: const [
        SizedBox(height: 12),
        Text(
          'A simple to-do planner. Your tasks and settings are stored on this device.',
        ),
      ],
    );
  }

  Future<void> _pickPhoto(BuildContext context, ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked == null) return; // user cancelled
      final dir = await getApplicationDocumentsDirectory();
      final path =
          '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await File(picked.path).copy(path);
      settings.setProfileImage(path);
    } catch (_) {
      if (!context.mounted) return;
      _snack(
        context,
        source == ImageSource.camera
            ? 'Couldn’t open the camera'
            : 'Couldn’t open your photos',
      );
    }
  }

  void _showPhotoSheet(BuildContext context) {
    final pal = context.pal;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: pal.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  'Profile photo',
                  style: TextStyle(
                    color: pal.ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SettingsTile(
                icon: Icons.photo_library_outlined,
                color: AppColors.blue,
                title: 'Choose from gallery',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(context, ImageSource.gallery);
                },
              ),
              SettingsTile(
                icon: Icons.photo_camera_outlined,
                color: AppColors.green,
                title: 'Take a photo',
                onTap: () {
                  Navigator.pop(ctx);
                  _pickPhoto(context, ImageSource.camera);
                },
              ),
              if (settings.profileImagePath != null)
                SettingsTile(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.red,
                  title: 'Remove photo',
                  destructive: true,
                  onTap: () {
                    Navigator.pop(ctx);
                    settings.setProfileImage(null);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveSafeArea(
        child: ListenableBuilder(
          listenable: Listenable.merge([settings, store]),
          builder: (context, _) {
            final pal = context.pal;
            final name = settings.userName.trim();

            return ListView(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              children: [
                Row(
                  children: [
                    RoundIconButton(
                      icon: Icons.arrow_back_rounded,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Settings',
                      style: TextStyle(
                        color: pal.ink,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Profile card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: pal.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: pal.border),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => _showPhotoSheet(context),
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ProfileAvatar(
                              size: 64,
                              name: name,
                              imagePath: settings.profileImagePath,
                            ),
                            Positioned(
                              right: -4,
                              bottom: -4,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: pal.surface,
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 18),
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _editName(context),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name.isEmpty ? 'Add your name' : name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: pal.ink,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Tap to edit your name',
                                      style: TextStyle(
                                        color: pal.muted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.edit_outlined,
                                color: pal.muted,
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                SettingsSection(
                  title: 'Appearance',
                  children: const [_ThemeSelector()],
                ),
                const SizedBox(height: 24),

                SettingsSection(
                  title: 'Preferences',
                  children: [
                    SettingsTile(
                      icon: Icons.schedule_rounded,
                      color: AppColors.blue,
                      title: '24-hour time',
                      subtitle: 'Show times like 15:30',
                      trailing: Switch(
                        value: settings.use24h,
                        onChanged: settings.setUse24h,
                      ),
                      onTap: () => settings.setUse24h(!settings.use24h),
                    ),
                    SettingsTile(
                      icon: Icons.calendar_view_week_rounded,
                      color: AppColors.green,
                      title: 'Week starts on Monday',
                      subtitle: 'Turn off to start the week on Sunday',
                      trailing: Switch(
                        value: settings.weekStartsMonday,
                        onChanged: settings.setWeekStartsMonday,
                      ),
                      onTap: () => settings.setWeekStartsMonday(
                        !settings.weekStartsMonday,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SettingsSection(
                  title: 'Reminders',
                  children: [
                    SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      color: AppColors.red,
                      title: 'Task reminders',
                      subtitle: 'Get notified before your tasks start',
                      trailing: Switch(
                        value: settings.remindersEnabled,
                        onChanged: (v) => _toggleReminders(context, v),
                      ),
                      onTap: () =>
                          _toggleReminders(context, !settings.remindersEnabled),
                    ),
                    SettingsTile(
                      icon: Icons.send_rounded,
                      color: AppColors.blue,
                      title: 'Send a test notification',
                      subtitle: 'Check that reminders work on this phone',
                      onTap: () => _testNotification(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SettingsSection(
                  title: 'Your data',
                  children: [
                    SettingsTile(
                      icon: Icons.cleaning_services_rounded,
                      color: AppColors.amber,
                      title: 'Clear completed tasks',
                      subtitle: '${store.completedCount} completed',
                      onTap: () => _clearCompleted(context),
                    ),
                    SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.red,
                      title: 'Delete all tasks',
                      destructive: true,
                      onTap: () => _deleteAll(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                SettingsSection(
                  title: 'Help & about',
                  children: [
                    SettingsTile(
                      icon: Icons.lightbulb_outline_rounded,
                      color: AppColors.amber,
                      title: 'How it works',
                      onTap: () => _showHelp(context),
                    ),
                    SettingsTile(
                      icon: Icons.info_outline_rounded,
                      color: AppColors.blue,
                      title: 'About $appName',
                      subtitle: 'Version $appVersion',
                      onTap: () => _showAbout(context),
                    ),
                  ],
                ),
                const SizedBox(height: 28),

                Center(
                  child: Text(
                    '$appName v$appVersion',
                    style: TextStyle(color: pal.muted, fontSize: 12),
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

// ───────────────────── Theme selector ─────────────────────
class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector();

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    const choices = [
      (ThemeMode.system, Icons.brightness_auto_rounded, 'System'),
      (ThemeMode.light, Icons.light_mode_rounded, 'Light'),
      (ThemeMode.dark, Icons.dark_mode_rounded, 'Dark'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const IconBadge(
                icon: Icons.palette_outlined,
                color: AppColors.blue,
              ),
              const SizedBox(width: 14),
              Text(
                'Theme',
                style: TextStyle(
                  color: pal.ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              for (var i = 0; i < choices.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _ThemeChoice(
                    icon: choices[i].$2,
                    label: choices[i].$3,
                    selected: settings.themeMode == choices[i].$1,
                    onTap: () => settings.setThemeMode(choices[i].$1),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.blue.withAlpha(28) : pal.field,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 22, color: selected ? AppColors.blue : pal.muted),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.blue : pal.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ───────────────────── Name dialog ─────────────────────
class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 24,
        textCapitalization: TextCapitalization.words,
        decoration: const InputDecoration(hintText: 'e.g. Alex'),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
