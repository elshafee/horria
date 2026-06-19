import 'package:flutter/material.dart';

/// Centralized Theme configuration for Dr. Houria application.
class RobotTheme {
  // --- Colors ---
  
  /// Primary dominant purple color used in sidebars and major headers.
  static const Color primaryPurple = Color(0xFF65418F);
  
  /// Lighter variant of purple often used for secondary headers or inactive states.
  static const Color lightPurple = Color(0xFF6A4294);
  
  /// The global background color of the application screens.
  static const Color backgroundLight = Color(0xFFF9F7FA);
  
  /// Accent pink used for primary actions, badges, and progress indicators.
  static const Color accentPink = Color(0xFFFF85A1);
  
  /// Darker text color used for high-contrast reading text.
  static const Color darkText = Color(0xFF2D2340);
  
  /// Medical/Matrix green used explicitly for graphing lines like ECG.
  static const Color medicalGreen = Color(0xFF00FF41);
  
  /// Generic grey color used for subtitles and normal range indicators.
  static const Color textGrey = Colors.grey;

  // --- Text Styles ---

  static const TextStyle header1 = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.bold,
    color: primaryPurple,
  );

  static const TextStyle header2 = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: primaryPurple,
  );

  static const TextStyle subtitle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: accentPink,
  );

  static const TextStyle bodyText = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: darkText,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 18,
    color: textGrey,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: Colors.white,
  );
}
