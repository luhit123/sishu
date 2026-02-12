import 'package:flutter/material.dart';

/// XoruCare color system.
/// Direction: clinical trust + warm family-friendly accents.
abstract final class AppColors {
  // Brand core
  static const Color primary = Color(0xFF0F8A7A);
  static const Color primaryLight = Color(0xFF4AB7A9);
  static const Color primaryDark = Color(0xFF0A5F56);
  static const Color primaryPastel = Color(0xFFDDF5F1);

  static const Color secondary = Color(0xFF2D6CDF);
  static const Color secondaryLight = Color(0xFF7EA4F0);
  static const Color secondaryDark = Color(0xFF1E4AA6);
  static const Color secondaryPastel = Color(0xFFE3ECFF);

  // Accent family
  static const Color lavender = Color(0xFF6372C8);
  static const Color lavenderLight = Color(0xFFE4E8FA);
  static const Color peach = Color(0xFFF08A55);
  static const Color peachLight = Color(0xFFFFE8D8);
  static const Color mintCream = Color(0xFF53C9A7);
  static const Color mintCreamLight = Color(0xFFDDF8EF);
  static const Color softPink = Color(0xFFE97883);
  static const Color softPinkLight = Color(0xFFFFE6EA);
  static const Color softYellow = Color(0xFFE4B238);
  static const Color softYellowLight = Color(0xFFFFF3D5);
  static const Color softCoral = Color(0xFFF16B5A);
  static const Color softCoralLight = Color(0xFFFFE4E0);

  // Neutrals
  static const Color background = Color(0xFFF3F7FC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEBF1F8);
  static const Color surfaceWarm = Color(0xFFFFF7EE);

  // Typography
  static const Color textPrimary = Color(0xFF0F1C2E);
  static const Color textSecondary = Color(0xFF43536B);
  static const Color textHint = Color(0xFF6E7C93);

  // Semantic states
  static const Color error = Color(0xFFC63E40);
  static const Color errorLight = Color(0xFFFFE3E4);
  static const Color success = Color(0xFF1E8A5C);
  static const Color successLight = Color(0xFFDBF3E8);
  static const Color warning = Color(0xFFB27A00);
  static const Color warningLight = Color(0xFFFFF0CC);
  static const Color info = Color(0xFF2D6CDF);
  static const Color infoLight = Color(0xFFE3ECFF);
}
