import 'package:flutter/material.dart';
import '../../core/theme/robot_theme.dart';

/// A globally reusable primary button that aligns with the SDUI design language.
class SduiPrimaryButton extends StatefulWidget {
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
  State<SduiPrimaryButton> createState() => _SduiPrimaryButtonState();
}

class _SduiPrimaryButtonState extends State<SduiPrimaryButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: SizedBox(
          width: widget.isFullWidth ? double.infinity : null,
          height: 55,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.backgroundColor,
              elevation: _isPressed ? 0 : 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              widget.text,
              style: RobotTheme.buttonText,
            ),
          ),
        ),
      ),
    );
  }
}
