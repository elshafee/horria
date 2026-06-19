enum MeasurementType {
  bloodPressure,
  ecg,
  glucose,
  oxygen,
  heartRate,
  temperature,
}

extension MeasurementTypeExtension on MeasurementType {
  String get title {
    switch (this) {
      case MeasurementType.bloodPressure:
        return 'قياس ضغط الدم';
      case MeasurementType.ecg:
        return 'تخطيط القلب';
      case MeasurementType.glucose:
        return 'قياس السكر';
      case MeasurementType.oxygen:
        return 'نسبة الأكسجين';
      case MeasurementType.heartRate:
        return 'معدل نبضات القلب';
      case MeasurementType.temperature:
        return 'درجة الحرارة';
    }
  }

  String get expectedEvent {
    switch (this) {
      case MeasurementType.bloodPressure:
        return 'bpResult';
      case MeasurementType.ecg:
        return 'ecgResult';
      case MeasurementType.glucose:
        return 'resultReceived';
      case MeasurementType.temperature:
        return 'tempResult';
      case MeasurementType.oxygen:
      case MeasurementType.heartRate:
        return 'oxyParam';
    }
  }

  List<Map<String, String>> get instructions {
    switch (this) {
      case MeasurementType.bloodPressure:
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'ضع ذراعك على الطاولة\nبحيث تكون مستندة وعلى مستوى القلب',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_ins_arm_on_table.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'ركب كفة الضغط\nأعلى المرفق بحوالي 2 - 3 سم',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_cuff_distance.png',
          },
          {
            'step': 'الخطوة 3 :',
            'instruction': 'انتظر بهدوء\nلا تتحدث أو تتحرك حتى ينتهي القياس',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_set_calm.png',
          },
        ];
      case MeasurementType.ecg:
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'ضع أصابعك على المستشعرات المعدنية الجانبية للجهاز.',
            'image': 'assets/images/measurements/instructions/ecg/step 1.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'حافظ على ثباتك وتنفس بشكل طبيعي حتى انتهاء شريط التقدم.',
            'image': 'assets/images/measurements/instructions/ecg/step2.png',
          },
        ];
      case MeasurementType.glucose:
        return [
          {
            'step': '1',
            'instruction': 'أدخل شريط الاختبار في الجهاز.',
          },
          {
            'step': '2',
            'instruction': 'استخدم أداة الوخز للحصول على قطرة دم صغيرة.',
          },
          {
            'step': '3',
            'instruction': 'ضع قطرة الدم على شريط الاختبار.',
          },
          {
            'step': '4',
            'instruction': 'انتظر ظهور النتيجة على الشاشة.',
          },
        ];
      case MeasurementType.oxygen:
      case MeasurementType.heartRate:
        return [
          {
            'step': '1',
            'instruction': 'اجلس بهدوء',
          },
          {
            'step': '2',
            'instruction': 'استخدم إصبع نظيف وجاف',
          },
          {
            'step': '3',
            'instruction': 'ضع الجهاز على السبابة',
          },
          {
            'step': '4',
            'instruction': 'ثبت يدك وانتظر النتيجة',
          },
        ];
      case MeasurementType.temperature:
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'قم بتوجيه مستشعر الجهاز نحو منتصف الجبهة على مسافة 3 - 5 سم واضغط زر القياس.',
            'image': 'assets/images/measurements/instructions/temperature/temp.png',
          },
        ];
      default:
        // Generic instructions for other types
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'يرجى تركيب الجهاز بشكل صحيح',
            'image': 'assets/images/measurements/instructions/${name}/step1.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'انتظر بهدوء\nلا تتحدث أو تتحرك حتى ينتهي القياس',
            'image': 'assets/images/measurements/instructions/${name}/step2.png',
          },
        ];
    }
  }

  String get name {
    switch (this) {
      case MeasurementType.bloodPressure: return 'blood_pressure';
      case MeasurementType.ecg: return 'ECG';
      case MeasurementType.glucose: return 'glucose';
      case MeasurementType.oxygen: return 'oxygen';
      case MeasurementType.heartRate: return 'heart_rate';
      case MeasurementType.temperature: return 'temperature';
    }
  }
}
