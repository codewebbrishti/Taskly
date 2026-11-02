import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded avatar. Shows the chosen photo, else the first letter of the
/// name, else a person icon.
class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.size = 44,
    this.name = '',
    this.imagePath,
  });

  final double size;
  final String name;
  final String? imagePath;

  static const _ink = Color(0xFF1F1F4D);

  Widget _fallback(String trimmed) {
    return Center(
      child: trimmed.isEmpty
          ? Icon(Icons.person_rounded, color: _ink, size: size * 0.6)
          : Text(
              String.fromCharCode(trimmed.runes.first).toUpperCase(),
              style: TextStyle(
                color: _ink,
                fontSize: size * 0.42,
                fontWeight: FontWeight.w800,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final path = imagePath;
    final hasImage = path != null && File(path).existsSync();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.amber,
        borderRadius: BorderRadius.circular(size * 0.32),
        boxShadow: [
          BoxShadow(
            color: AppColors.amber.withAlpha(90),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.32),
        child: hasImage
            ? Image.file(
                File(path),
                width: size,
                height: size,
                fit: BoxFit.cover,
                cacheWidth: (size * 3).round(),
                errorBuilder: (_, _, _) => _fallback(trimmed),
              )
            : _fallback(trimmed),
      ),
    );
  }
}
