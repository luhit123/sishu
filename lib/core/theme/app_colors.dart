import 'package:flutter/material.dart';

/// Sishu app color palette
/// Designed for calm, soothing pediatric UI with trust-first approach
/// Soft pastels that feel warm, safe, and child-friendly
/// Enhanced contrast for better readability
abstract final class AppColors {
  // Primary: Sage Green - calming, natural, growth
  static const Color primary = Color(0xFF3D9070);  // Deeper rich green
  static const Color primaryLight = Color(0xFF6BB89A);
  static const Color primaryDark = Color(0xFF2A6B52);  // Much darker
  static const Color primaryPastel = Color(0xFFDEEFE7);

  // Secondary: Sky Blue - trust, clarity, calm
  static const Color secondary = Color(0xFF5A90B8);  // Deeper blue
  static const Color secondaryLight = Color(0xFF8BB8D5);
  static const Color secondaryDark = Color(0xFF3D6F94);  // Much darker
  static const Color secondaryPastel = Color(0xFFDEEDF5);

  // Accent Colors - Richer pastels for better visibility
  static const Color lavender = Color(0xFF9080BC);  // Richer purple
  static const Color lavenderLight = Color(0xFFDED9EB);
  static const Color peach = Color(0xFFEB9A70);  // Richer peach
  static const Color peachLight = Color(0xFFFCE6DA);
  static const Color mintCream = Color(0xFF70CCA0);  // Richer mint
  static const Color mintCreamLight = Color(0xFFDAF5E8);
  static const Color softPink = Color(0xFFEB8FA0);  // Deeper pink
  static const Color softPinkLight = Color(0xFFFBE5EA);
  static const Color softYellow = Color(0xFFF0C840);  // Rich gold
  static const Color softYellowLight = Color(0xFFFCF4D6);
  static const Color softCoral = Color(0xFFF08888);  // Richer coral
  static const Color softCoralLight = Color(0xFFFCE5E5);

  // Background: Warm off-white
  static const Color background = Color(0xFFF6F8F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFEBEDE9);  // More visible
  static const Color surfaceWarm = Color(0xFFFFF8F2);

  // Text colors (stronger contrast for readability)
  static const Color textPrimary = Color(0xFF1A2530);  // Much darker
  static const Color textSecondary = Color(0xFF4D5B68);  // Darker
  static const Color textHint = Color(0xFF7A8B96);  // Darker hints

  // Feedback colors - Richer but still non-alarming
  static const Color error = Color(0xFFD96850);  // Richer red-orange
  static const Color errorLight = Color(0xFFFBE3DD);
  static const Color success = Color(0xFF5A9575);  // Richer green
  static const Color successLight = Color(0xFFDDEFE5);
  static const Color warning = Color(0xFFDEA530);  // Rich amber
  static const Color warningLight = Color(0xFFFCF0D4);
  static const Color info = Color(0xFF5A90B8);
  static const Color infoLight = Color(0xFFDEEDF5);
}
