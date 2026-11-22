import 'package:flutter/material.dart';
import '../../data/models/sdui_payload_model.dart';
import '../../core/theme/robot_theme.dart';
import '../../core/routes/app_router.dart';
import '../../models/measurement_type.dart';

/// A pure, decoupled widget representing a Vital Sign selection card.
/// It receives all its data and styling purely through [SduiVitalCardPayload]
/// and emits tap events via a generic callback or handles measurement navigation.
class SduiVitalCard extends StatelessWidget {
  final SduiVitalCardPayload payload;
  final MeasurementType? type;
  final ValueChanged<String>? onActionTriggered;

  const SduiVitalCard({
    super.key,
    required this.payload,
    this.type,
    this.onActionTriggered,
  });

  @override
  Widget build(BuildContext context) {
    // Gracefully handle server visibility flags
    if (!payload.isVisible) {
      return const SizedBox.shrink();
    }

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(25),
      child: InkWell(
        borderRadius: BorderRadius.circular(25),
        onTap: () {
          // If a specific measurement type is provided, navigate directly
          if (type != null) {
            Navigator.pushNamed(
              context,
              AppRouter.measurementInstruction,
              arguments: type,
            );
          } 
          // Emit the route action string without coupling to BuildContext or Navigator if callback exists
          else if (payload.routeAction != null && onActionTriggered != null) {
            onActionTriggered!(payload.routeAction!);
          }
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.all(5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: Image.asset(
                  payload.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Safe fallback if the backend sends an invalid image path
                    return const Icon(
                      Icons.image_not_supported,
                      color: RobotTheme.textGrey,
                      size: 40,
                    );
                  },
                ),
              ),
              if (payload.title.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  payload.title,
                  style: RobotTheme.subtitle,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
