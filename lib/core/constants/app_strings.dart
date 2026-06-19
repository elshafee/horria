/// Centralized repository for all UI text strings.
/// This acts as a foundation for future internationalization (i18n).
class AppStrings {
  // General App
  static const String appTitle = 'Dr. Houria Dashboard';
  static const String battery = 'Battery:';
  static const String disconnected = 'Disconnected';
  static const String connecting = 'Connecting...';
  
  // Onboarding & Splash
  static const String splashTitle = 'Dr. Houria';
  static const String selectLanguage = 'اختيار اللغة';
  static const String languageArabic = 'اللغة العربية';
  static const String languageEnglish = 'English';
  static const String continueBtn = 'متابعة';

  // Auth
  static const String loginTitle = 'تسجيل الدخول';
  static const String registerTitle = 'إنشاء حساب جديد';
  static const String usernameHint = 'اسم المستخدم';
  static const String passwordHint = 'كلمة المرور';
  static const String noAccount = 'ليس لديك حساب؟ ';
  static const String haveAccount = 'لديك حساب بالفعل؟ ';

  // Dashboard & Navigation
  static const String homeTab = 'الرئيسية';
  static const String measurementsTab = 'القياسات';
  static const String recordsTab = 'السجلات';
  static const String historyTab = 'التاريخ';
  static const String profileTab = 'حسابي';
  static const String logout = 'تسجيل الخروج';
  static const String dataLog = 'سجل البيانات';
  static const String clearLog = 'مسح السجل';
  static const String noDataLog = 'لا يوجد بيانات حتى الآن';

  // Measurements
  static const String measurementInstructionTitle = 'تعليمات القياس';
  static const String measurementInstructionSubtitle = 'من فضلك اتبع التعليمات والصور بدقة';
  static const String startMeasurementBtn = 'ابدأ القياس';
  static const String nextBtn = 'التالي';
  static const String previousBtn = 'السابق';
  static const String measuringStatus = 'جاري القياس...';
  static const String measuringSuccess = 'تم القياس بنجاح';
  static const String measuringError = 'حدث خطأ في القياس';
  static const String currentPressure = 'الضغط الحالي:';
  static const String showResultBtn = 'أظهر النتيجة';
  static const String measurementResultTitle = 'نتيجة القياس';
  
  // Vitals
  static const String bloodPressure = 'ضغط الدم';
  static const String heartRate = 'معدل ضربات القلب';
  static const String bloodOxygen = 'نسبة الأكسجين';
  static const String bodyTemperature = 'درجة الحرارة';
  static const String bloodGlucose = 'سكر الدم';
  static const String ecg = 'تخطيط القلب';
}
