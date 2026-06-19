import 'package:flutter/material.dart';
import '../../core/theme/robot_theme.dart';

/// A globally reusable primary button that aligns with the SDUI design language.
class SduiPrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color backgroundColor;
  final bool isFullWidth;

  const SduiPrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.backgroundColor = RobotTheme.primaryPurple,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: Text(
          text,
          style: RobotTheme.buttonText,
        ),
      ),
    );
  }
}
