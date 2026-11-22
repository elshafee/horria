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
            'instruction': 'اجلس وأسند ذراعك اليسرى على الطاولة في مستوى القلب.',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_ins_arm_on_table.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'لف الحزام حول ذراعك بإحكام فوق المرفق بـ 2 سنتيمتر.',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_cuff_distance.png',
          },
          {
            'step': 'الخطوة 3 :',
            'instruction': 'ابق هادئاً ولا تتحرك أو تتحدث حتى تظهر النتيجة.',
            'image': 'assets/images/measurements/instructions/blood_pressure/bp_set_calm.png',
          },
        ];
      case MeasurementType.ecg:
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'شغل الجهاز، وضع إبهاميك على المستشعرات الجانبية بلطف.',
            'image': 'assets/images/measurements/instructions/ecg/step 1.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'ثبت يديك تماماً وتنفس بهدوء حتى ينتهي القياس.',
            'image': 'assets/images/measurements/instructions/ecg/step2.png',
          },
        ];
      case MeasurementType.glucose:
        return [
          {
            'step': '1',
            'instruction': 'اغسل يديك بالماء الدافئ وجففها جيداً.',
          },
          {
            'step': '2',
            'instruction': 'أدخل شريط الاختبار في الجهاز ليتم تشغيله.',
          },
          {
            'step': '3',
            'instruction': 'استخدم القلم لعمل وخزة صغيرة في طرف إصبعك.',
          },
          {
            'step': '4',
            'instruction': 'قرب قطرة الدم من شريط الاختبار وانتظر النتيجة.',
          },
        ];
      case MeasurementType.oxygen:
      case MeasurementType.heartRate:
        return [
          {
            'step': '1',
            'instruction': 'تأكد من نظافة إصبعك وخلوه من طلاء الأظافر.',
          },
          {
            'step': '2',
            'instruction': 'أدخل إصبعك داخل جهاز القياس حتى النهاية.',
          },
          {
            'step': '3',
            'instruction': 'أسند يدك على الطاولة لتجنب الاهتزاز.',
          },
          {
            'step': '4',
            'instruction': 'شغل الجهاز وابق هادئاً حتى تظهر النتيجة.',
          },
        ];
      case MeasurementType.temperature:
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'وجه الجهاز نحو منتصف الجبهة بمسافة 3-5 سنتيمتر واضغط على زر القياس.',
            'image': 'assets/images/measurements/instructions/temperature/temp.png',
          },
        ];
      default:
        // Generic instructions for other types
        return [
          {
            'step': 'الخطوة 1 :',
            'instruction': 'قم بتركيب الجهاز بشكل صحيح في مكانه المناسب.',
            'image': 'assets/images/measurements/instructions/${name}/step1.png',
          },
          {
            'step': 'الخطوة 2 :',
            'instruction': 'ابق هادئاً ولا تتحرك حتى تظهر النتيجة.',
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
