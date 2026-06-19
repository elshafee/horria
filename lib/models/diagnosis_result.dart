import 'measurement_type.dart';

class DiagnosisResult {
  final String title;
  final String probabilityText;
  final int percentage;
  final List<String> symptoms;
  final List<Recommendation> recommendations;

  DiagnosisResult({
    required this.title,
    required this.probabilityText,
    required this.percentage,
    required this.symptoms,
    this.recommendations = const [],
  });

  factory DiagnosisResult.fromMap(Map<String, dynamic> map) {
    return DiagnosisResult(
      title: map['title'] ?? map['condition'] ?? 'Unknown',
      probabilityText: map['probability_text'] ?? (map['percentage'] != null ? 'احتمالية ${map['percentage']}%' : 'احتمالية متوسطة'),
      percentage: map['percentage'] ?? 50,
      symptoms: (map['symptoms'] as List<dynamic>?)?.cast<String>() ?? [],
      recommendations: (map['recommendations'] as List<dynamic>?)
          ?.map((r) => Recommendation.fromMap(r as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}

class Recommendation {
  final String title;
  final List<String> items;
  final RecommendationType type;
  final List<MeasurementType>? requiredMeasurements;

  Recommendation({
    required this.title,
    required this.items,
    required this.type,
    this.requiredMeasurements,
  });

  factory Recommendation.fromMap(Map<String, dynamic> map) {
    return Recommendation(
      title: map['title'] ?? 'توصية',
      items: (map['items'] as List<dynamic>?)?.cast<String>() ?? [],
      type: _parseType(map['type']),
      requiredMeasurements: (map['measurements'] as List<dynamic>?)
          ?.map((m) => _parseMeasurementType(m))
          .whereType<MeasurementType>()
          .toList(),
    );
  }

  static RecommendationType _parseType(dynamic type) {
    switch (type?.toString().toLowerCase()) {
      case 'measurements': return RecommendationType.measurements;
      case 'labtests': return RecommendationType.labTests;
      case 'clinic': return RecommendationType.clinic;
      default: return RecommendationType.measurements;
    }
  }

  static MeasurementType? _parseMeasurementType(dynamic m) {
    final s = m.toString().toLowerCase();
    if (s.contains('pressure')) return MeasurementType.bloodPressure;
    if (s.contains('ecg')) return MeasurementType.ecg;
    if (s.contains('glucose') || s.contains('sugar')) return MeasurementType.glucose;
    if (s.contains('oxygen') || s.contains('spo2')) return MeasurementType.oxygen;
    if (s.contains('heart') || s.contains('pulse')) return MeasurementType.heartRate;
    if (s.contains('temp')) return MeasurementType.temperature;
    return null;
  }
}

enum RecommendationType {
  measurements,
  labTests,
  clinic,
}

class DiagnosisReport {
  final String robotMessage;
  final List<DiagnosisResult> results;

  DiagnosisReport({
    required this.robotMessage,
    required this.results,
  });

  factory DiagnosisReport.fromMap(Map<String, dynamic> map) {
    return DiagnosisReport(
      robotMessage: map['robot_message'] ?? 'بناءً على أعراضك، هذه أقرب الاحتمالات',
      results: (map['results'] as List<dynamic>?)
          ?.map((r) => DiagnosisResult.fromMap(r as Map<String, dynamic>))
          .toList() ?? [],
    );
  }
}
