import 'dart:io';
import 'package:flutter/material.dart';

/// Unified company logo avatar that supports both local file paths and network URLs.
/// Falls back to an icon when no logo is available.
class CompanyLogoAvatar extends StatelessWidget {
  final String? logoPathOrUrl;
  final double size; // total width/height
  final bool circular;
  final Color? backgroundColor;
  final IconData fallbackIcon;
  final Color? fallbackIconColor;

  const CompanyLogoAvatar({
    super.key,
    required this.logoPathOrUrl,
    this.size = 32,
    this.circular = true,
    this.backgroundColor,
    this.fallbackIcon = Icons.business,
    this.fallbackIconColor,
  });

  bool get _hasLogo =>
      logoPathOrUrl != null && logoPathOrUrl!.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final double radius = size / 2;

    ImageProvider? imageProvider;
    if (_hasLogo) {
      final path = logoPathOrUrl!.trim();
      if (path.startsWith('http')) {
        imageProvider = NetworkImage(path);
      } else {
        try {
          final file = File(path);
          if (file.existsSync()) {
            imageProvider = FileImage(file);
          }
        } catch (_) {
          imageProvider = null;
        }
      }
    }

    final Color resolvedBg = backgroundColor ?? Colors.blueGrey.shade100;
    final Color resolvedIcon = fallbackIconColor ?? Colors.blueGrey.shade700;

    if (circular) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: resolvedBg,
        backgroundImage: imageProvider,
        child: imageProvider == null
            ? Icon(fallbackIcon, size: size * 0.5, color: resolvedIcon)
            : null,
      );
    }

    // Square variant
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: resolvedBg,
        borderRadius: BorderRadius.circular(6),
        image: imageProvider != null
            ? DecorationImage(image: imageProvider, fit: BoxFit.cover)
            : null,
      ),
      child: imageProvider == null
          ? Icon(fallbackIcon, size: size * 0.5, color: resolvedIcon)
          : null,
    );
  }
}
