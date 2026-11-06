import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:ota_update/ota_update.dart';

import '../services/update_service.dart';
import '../theme/app_colors.dart';
import '../utils/constants.dart';

/// "Check for updates": looks for a newer release, asks, downloads and installs.
Future<void> checkForUpdates(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context, rootNavigator: true);

  void snack(String message) {
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  if (!Platform.isAndroid) {
    snack('In-app updates are available on Android only.');
    return;
  }

  // Small spinner while we look
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const PopScope(
      canPop: false,
      child: Center(child: CircularProgressIndicator()),
    ),
  );

  UpdateInfo? info;
  String? error;
  try {
    info = await updates.checkForUpdate();
  } on UpdateException catch (e) {
    error = e.message;
  } catch (_) {
    error =
        'Couldn’t reach GitHub. Check your internet connection and try again.';
  }
  navigator.pop(); // close the spinner
  if (!context.mounted) return;

  if (error != null) {
    snack(error);
    return;
  }
  final found = info;
  if (found == null) {
    snack('You’re on the latest version (${updates.installedVersion}).');
    return;
  }

  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Update available'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$appName ${found.version} is ready. '
            'You have ${updates.installedVersion}.',
          ),
          if (found.notes.isNotEmpty) ...[
            const SizedBox(height: 12),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 160),
              child: SingleChildScrollView(
                child: Text(found.notes, style: const TextStyle(fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Later'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Update now'),
        ),
      ],
    ),
  );
  if (go != true || !context.mounted) return;

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _DownloadDialog(info: found),
  );
}

class _DownloadDialog extends StatefulWidget {
  const _DownloadDialog({required this.info});
  final UpdateInfo info;

  @override
  State<_DownloadDialog> createState() => _DownloadDialogState();
}

class _DownloadDialogState extends State<_DownloadDialog> {
  StreamSubscription<OtaEvent>? _sub;
  double? _progress;
  String _status = 'Starting download…';
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  void _start() {
    try {
      _sub = OtaUpdate()
          .execute(
            widget.info.apkUrl,
            destinationFilename: 'taskly-${widget.info.version}.apk',
          )
          .listen(
            _onEvent,
            onError: (Object e) => _fail('The download failed: $e'),
          );
    } catch (e) {
      _fail('The update couldn’t start: $e');
    }
  }

  void _onEvent(OtaEvent event) {
    if (!mounted) return;
    switch (event.status.name) {
      case 'DOWNLOADING':
        final percent = int.tryParse(event.value ?? '');
        setState(() {
          _progress = percent == null ? null : percent / 100;
          _status = percent == null ? 'Downloading…' : 'Downloading… $percent%';
        });
        break;
      case 'INSTALLING':
      case 'INSTALLATION_DONE':
      case 'CANCELED':
        Navigator.of(context).pop(); // the system installer takes over
        break;
      case 'PERMISSION_NOT_GRANTED_ERROR':
        _fail(
          'Allow “Install unknown apps” for $appName in your phone settings, then try again.',
        );
        break;
      case 'ALREADY_RUNNING_ERROR':
        _fail('An update is already downloading.');
        break;
      default:
        _fail(
          'The update failed (${event.status.name}'
          '${event.value != null ? ': ${event.value}' : ''}).',
        );
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    setState(() => _error = message);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text(_error == null ? 'Updating $appName' : 'Update problem'),
        content: _error != null
            ? Text(_error!)
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_status),
                  const SizedBox(height: 14),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: _progress,
                      minHeight: 6,
                      color: AppColors.blue,
                    ),
                  ),
                ],
              ),
        actions: [
          TextButton(
            onPressed: () {
              if (_error == null) {
                try {
                  OtaUpdate().cancel();
                } catch (_) {}
              }
              Navigator.of(context).pop();
            },
            child: Text(_error == null ? 'Cancel' : 'Close'),
          ),
        ],
      ),
    );
  }
}
