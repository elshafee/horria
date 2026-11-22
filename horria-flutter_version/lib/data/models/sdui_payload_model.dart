/// Base class for all SDUI Components.
abstract class SduiComponent {
  final String id;
  final String type;

  const SduiComponent({
    required this.id,
    required this.type,
  });

  factory SduiComponent.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    
    switch (type) {
      case 'VitalCard':
        return SduiVitalCardPayload.fromJson(json);
      // Add other component types here as they are refactored
      default:
        return SduiUnknownComponent(
          id: json['id']?.toString() ?? 'unknown_id',
          type: type ?? 'unknown_type',
        );
    }
  }
}

/// Fallback component when the server sends an unsupported type.
class SduiUnknownComponent extends SduiComponent {
  const SduiUnknownComponent({required super.id, required super.type});
}

/// Payload model specifically for the VitalCard global widget.
class SduiVitalCardPayload extends SduiComponent {
  final String imagePath;
  final String title;
  final String? routeAction;
  final bool isVisible;
  final Map<String, dynamic> customData;

  const SduiVitalCardPayload({
    required super.id,
    required super.type,
    required this.imagePath,
    required this.title,
    this.routeAction,
    this.isVisible = true,
    this.customData = const {},
  });

  /// Safely parses JSON with aggressive fallback defaults to prevent null crashes.
  factory SduiVitalCardPayload.fromJson(Map<String, dynamic> json) {
    return SduiVitalCardPayload(
      id: json['id']?.toString() ?? 'vital_card_default_id',
      type: json['type']?.toString() ?? 'VitalCard',
      
      // Fallback to a placeholder if the server omits the image path
      imagePath: json['imagePath']?.toString() ?? 'assets/images/common/robot_icon.png',
      
      // Default to empty string instead of null
      title: json['title']?.toString() ?? '',
      
      // Nullable action identifier for the UI layer to resolve
      routeAction: json['routeAction']?.toString(),
      
      // Safely parse boolean visibility, defaulting to true
      isVisible: json['isVisible'] is bool ? json['isVisible'] : true,
      
      // Safely extract custom JSON payload for any specific parameter needs
      customData: json['customData'] is Map<String, dynamic> ? json['customData'] : {},
    );
  }
}
