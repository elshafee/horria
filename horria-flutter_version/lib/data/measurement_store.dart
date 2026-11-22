import '../models/measurement_type.dart';

class MeasurementResultData {
  final MeasurementType type;
  final String title;
  final String value;
  final String unit;
  final String normalRange;
  final bool isNormal;
  final String statusClass;
  final String time;
  final DateTime timestamp;
  final List<double>? ecgWavePoints;
  final String? ecgResultMessage;
  final int? ecgDiagnosisResult;

  MeasurementResultData({
    required this.type,
    required this.title,
    required this.value,
    required this.unit,
    required this.normalRange,
    required this.isNormal,
    required this.statusClass,
    required this.time,
    required this.timestamp,
    this.ecgWavePoints,
    this.ecgResultMessage,
    this.ecgDiagnosisResult,
  });

  MeasurementResultData copyWith({
    String? value,
    bool? isNormal,
    String? statusClass,
    String? time,
    DateTime? timestamp,
    List<double>? ecgWavePoints,
    String? ecgResultMessage,
    int? ecgDiagnosisResult,
  }) {
    return MeasurementResultData(
      type: type,
      title: title,
      value: value ?? this.value,
      unit: unit,
      normalRange: normalRange,
      isNormal: isNormal ?? this.isNormal,
      statusClass: statusClass ?? this.statusClass,
      time: time ?? this.time,
      timestamp: timestamp ?? this.timestamp,
      ecgWavePoints: ecgWavePoints ?? this.ecgWavePoints,
      ecgResultMessage: ecgResultMessage ?? this.ecgResultMessage,
      ecgDiagnosisResult: ecgDiagnosisResult ?? this.ecgDiagnosisResult,
    );
  }
}

class MeasurementStore {
  // Singleton pattern
  static final MeasurementStore _instance = MeasurementStore._internal();
  factory MeasurementStore() => _instance;

  MeasurementStore._internal() {
    _initDefaultValues();
  }

  final Map<MeasurementType, MeasurementResultData> _measurements = {};

  void _initDefaultValues() {
    final now = DateTime.now();
    _measurements[MeasurementType.glucose] = MeasurementResultData(
      type: MeasurementType.glucose,
      title: 'سكر الدم',
      value: '--',
      unit: 'mg/dL',
      normalRange: '70 - 100',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );

    _measurements[MeasurementType.ecg] = MeasurementResultData(
      type: MeasurementType.ecg,
      title: 'رسم القلب',
      value: '--',
      unit: 'bpm',
      normalRange: '60 - 100',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );

    _measurements[MeasurementType.bloodPressure] = MeasurementResultData(
      type: MeasurementType.bloodPressure,
      title: 'ضغط الدم',
      value: '--/--',
      unit: 'mmHg',
      normalRange: '120/80',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );

    _measurements[MeasurementType.oxygen] = MeasurementResultData(
      type: MeasurementType.oxygen,
      title: 'نسبة الأكسجين في الدم',
      value: '--',
      unit: '%',
      normalRange: '95 - 100',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );

    _measurements[MeasurementType.heartRate] = MeasurementResultData(
      type: MeasurementType.heartRate,
      title: 'معدل نبضات القلب',
      value: '--',
      unit: 'bpm',
      normalRange: '60 - 100',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );

    _measurements[MeasurementType.temperature] = MeasurementResultData(
      type: MeasurementType.temperature,
      title: 'درجة الحرارة',
      value: '--',
      unit: '°C',
      normalRange: '36.0 - 37.5',
      isNormal: true,
      statusClass: 'غير متوفر',
      time: '--',
      timestamp: now,
    );
  }

  List<MeasurementResultData> getAllMeasurements() {
    return _measurements.values
        .where((m) => m.value != '--' && m.value != '--/--')
        .toList();
  }

  MeasurementResultData getMeasurement(MeasurementType type) {
    return _measurements[type]!;
  }

  void updateMeasurement(MeasurementType type, Map<String, dynamic>? resultData) {
    if (resultData == null) return;

    final now = DateTime.now();
    final timeStr = formatTimeArabic(now);

    String valStr = '--';
    bool isNormal = true;
    String statusClass = 'غير متوفر';

    // Helper to parse values safely
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    int parseInt(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    switch (type) {
      case MeasurementType.bloodPressure:
        final sys = parseInt(resultData['sys']);
        final dia = parseInt(resultData['dia']);
        valStr = '$sys/$dia';
        if (sys <= 120 && dia <= 80) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else if (sys < 90 || dia < 60) {
          isNormal = false;
          statusClass = 'منخفض';
        } else if (sys >= 140 || dia >= 90) {
          isNormal = false;
          statusClass = 'مرتفع';
        } else {
          isNormal = false;
          statusClass = 'مرتفع قليلاً';
        }
        break;

      case MeasurementType.oxygen:
        final spo2 = parseInt(resultData['spo2'] ?? resultData['value']);
        valStr = '$spo2';
        if (spo2 >= 95) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else {
          isNormal = false;
          statusClass = 'منخفض';
        }
        break;

      case MeasurementType.heartRate:
        final hr = parseInt(resultData['pr'] ?? resultData['hr'] ?? resultData['value']);
        valStr = '$hr';
        if (hr >= 60 && hr <= 100) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else if (hr < 60) {
          isNormal = false;
          statusClass = 'بطيء';
        } else {
          isNormal = false;
          statusClass = 'سريع';
        }
        break;

      case MeasurementType.temperature:
        final temp = parseDouble(resultData['temp'] ?? resultData['value']);
        valStr = temp.toStringAsFixed(1);
        if (temp >= 36.0 && temp <= 37.5) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else if (temp < 36.0) {
          isNormal = false;
          statusClass = 'منخفض';
        } else {
          isNormal = false;
          statusClass = 'مرتفع';
        }
        break;

      case MeasurementType.glucose:
        final glucose = parseInt(resultData['glucose'] ?? resultData['value']);
        valStr = '$glucose';
        if (glucose >= 70 && glucose <= 140) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else if (glucose < 70) {
          isNormal = false;
          statusClass = 'منخفض';
        } else {
          isNormal = false;
          statusClass = 'مرتفع';
        }
        break;

      case MeasurementType.ecg:
        final hr = parseInt(resultData['hr'] ?? resultData['value']);
        valStr = '$hr';
        if (hr >= 60 && hr <= 100) {
          isNormal = true;
          statusClass = 'طبيعي';
        } else if (hr < 60) {
          isNormal = false;
          statusClass = 'بطيء';
        } else {
          isNormal = false;
          statusClass = 'سريع';
        }
        break;
    }

    final current = _measurements[type]!;
    _measurements[type] = current.copyWith(
      value: valStr,
      isNormal: isNormal,
      statusClass: statusClass,
      time: timeStr,
      timestamp: now,
    );
  }

  /// Store ECG wave points and diagnosis info separately
  void updateEcgWaveData(List<double> wavePoints, {String? resultMessage, int? diagnosisResult}) {
    final current = _measurements[MeasurementType.ecg]!;
    _measurements[MeasurementType.ecg] = current.copyWith(
      ecgWavePoints: List<double>.from(wavePoints),
      ecgResultMessage: resultMessage,
      ecgDiagnosisResult: diagnosisResult,
    );
  }

  bool isAllNormal() {
    return _measurements.values.every((m) => m.isNormal);
  }

  List<String> getAbnormalMetrics() {
    return _measurements.values
        .where((m) => !m.isNormal)
        .map((m) => m.title)
        .toList();
  }

  DateTime getLatestUpdateTime() {
    DateTime latest = _measurements.values.first.timestamp;
    for (var m in _measurements.values) {
      if (m.timestamp.isAfter(latest)) {
        latest = m.timestamp;
      }
    }
    return latest;
  }

  static String formatTimeArabic(DateTime dt) {
    int hour = dt.hour;
    final int minute = dt.minute;
    final String period = hour >= 12 ? 'م' : 'ص';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final String minuteStr = minute.toString().padLeft(2, '0');
    return '$hour:$minuteStr $period';
  }

  static String formatDateArabic(DateTime dt) {
    final months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    int hour = dt.hour;
    final int minute = dt.minute;
    final String period = hour >= 12 ? 'مساءً' : 'صباحاً';
    if (hour > 12) hour -= 12;
    if (hour == 0) hour = 12;
    final String minuteStr = minute.toString().padLeft(2, '0');
    final String month = months[dt.month - 1];
    return '${dt.day} $month ${dt.year} - $hour:$minuteStr $period';
  }
}
