import 'package:flutter_test/flutter_test.dart';
import 'package:horria_t/data/measurement_store.dart';
import 'package:horria_t/models/measurement_type.dart';

void main() {
  group('MeasurementStore Tests', () {
    late MeasurementStore store;

    setUp(() {
      // Clean initialization of store defaults
      store = MeasurementStore();
    });

    test('Initializes with default values from mockup', () {
      final measurements = store.getAllMeasurements();
      expect(measurements.length, 6);

      // Verify glucose default value is 86
      final glucose = store.getMeasurement(MeasurementType.glucose);
      expect(glucose.value, '86');
      expect(glucose.unit, 'mg/dL');
      expect(glucose.isNormal, true);

      // Verify overall isAllNormal starts as true
      expect(store.isAllNormal(), true);
    });

    test('Updates glucose value and recalculates status', () {
      // Set an abnormal glucose value
      store.updateMeasurement(MeasurementType.glucose, {'value': 120});

      final glucose = store.getMeasurement(MeasurementType.glucose);
      expect(glucose.value, '120');
      expect(glucose.isNormal, false); // 120 is abnormal (not in 70 - 100)

      expect(store.isAllNormal(), false);
      expect(store.getAbnormalMetrics().contains('سكر الدم'), true);
    });

    test('Updates blood pressure value and validates sys/dia', () {
      // Set an abnormal BP value
      store.updateMeasurement(MeasurementType.bloodPressure, {
        'sys': 140,
        'dia': 90,
      });

      final bp = store.getMeasurement(MeasurementType.bloodPressure);
      expect(bp.value, '140/90');
      expect(bp.isNormal, false); // 140/90 is abnormal (sys > 120, dia > 80)

      expect(store.isAllNormal(), false);
    });

    test('Updates oxygen level and validates', () {
      // Normal oxygen
      store.updateMeasurement(MeasurementType.oxygen, {'value': 98});
      expect(store.getMeasurement(MeasurementType.oxygen).isNormal, true);

      // Abnormal oxygen
      store.updateMeasurement(MeasurementType.oxygen, {'value': 92});
      expect(store.getMeasurement(MeasurementType.oxygen).isNormal, false);
    });
  });
}
