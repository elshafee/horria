import 'package:flutter/material.dart';
import '../../core/theme/robot_theme.dart';

/// A global header banner widget for consistent top-of-screen styling.
class SduiHeaderBanner extends StatelessWidget {
  final String title;
  final VoidCallback onBack;
  final Color titleColor;
  final Widget? trailing;

  const SduiHeaderBanner({
    super.key,
    required this.title,
    required this.onBack,
    this.titleColor = RobotTheme.primaryPurple,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onBack,
          icon: const Icon(
            Icons.arrow_back_ios,
            color: RobotTheme.primaryPurple,
          ),
        ),
        Expanded(
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: RobotTheme.header2.copyWith(color: titleColor),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null)
          trailing!
        else
          // Placeholder to balance the row if there's no trailing widget
          const SizedBox(width: 48), 
      ],
    );
  }
}
