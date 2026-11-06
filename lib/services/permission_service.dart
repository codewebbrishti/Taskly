import 'dart:io' show Platform;

import 'package:permission_handler/permission_handler.dart';

enum PermissionOutcome { granted, denied, blocked }

/// Asks the user for camera / photo access before the app uses them.
class PermissionService {
  Future<PermissionOutcome> camera() async {
    return _outcome(await Permission.camera.request());
  }

  Future<PermissionOutcome> photos() async {
    if (!Platform.isAndroid) {
      return _outcome(await Permission.photos.request());
    }
    // Android 13+ asks for "photos"; Android 12 and older ask for "storage".
    final photos = await Permission.photos.request();
    if (photos.isGranted || photos.isLimited) return PermissionOutcome.granted;

    PermissionStatus? storage;
    try {
      storage = await Permission.storage.request();
    } catch (_) {}
    if (storage != null && storage.isGranted) return PermissionOutcome.granted;

    if (photos.isPermanentlyDenied || (storage?.isPermanentlyDenied ?? false)) {
      return PermissionOutcome.blocked;
    }
    return PermissionOutcome.denied;
  }

  PermissionOutcome _outcome(PermissionStatus s) {
    if (s.isGranted || s.isLimited) return PermissionOutcome.granted;
    if (s.isPermanentlyDenied || s.isRestricted)
      return PermissionOutcome.blocked;
    return PermissionOutcome.denied;
  }
}

final PermissionService permissions = PermissionService();
