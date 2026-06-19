import 'package:flutter/material.dart';

// Screens
import '../../onboarding/splash_screen.dart';
import '../../onboarding/select_language.dart';
import '../../auth/auth_main.dart';
import '../../auth/login/login_screen.dart';
import '../../auth/register/register.dart';
import '../../dashboard/dashboard.dart';
import '../../vital sign/vital_sig_home.dart';
import '../../views/measurements/measurement_instruction_screen.dart';
import '../../views/measurements/measurement_measuring_screen.dart';
import '../../views/measurements/measurement_result_screen.dart';
import '../../views/medical_record/medical_record_screen.dart';
import '../../views/medical_record/medical_history_screen.dart';
import '../../views/clinics/clinics_screen.dart';
import '../../views/clinics/clinic_requirements_screen.dart';
import '../../views/measurements/measurements_table_screen.dart';
import '../../views/scanner/scanner_home_screen.dart';
import '../../views/scanner/scanner_progress_screen.dart';
import '../../views/scanner/scanner_results_screen.dart';
import '../../views/diagnosis/diagnosis_home_screen.dart';
import '../../views/diagnosis/diagnosis_duration_screen.dart';
import '../../views/diagnosis/diagnosis_loading_screen.dart';
import '../../views/diagnosis/diagnosis_results_screen.dart';
import '../../views/diagnosis/diagnosis_recommendations_screen.dart';
import '../../models/measurement_type.dart';
import '../../presentation/screens/main_shell.dart';

import '../../views/diagnosis/ai_interview_screen.dart';

/// Centralized application router to decouple navigation logic from UI components.
class AppRouter {

  // Route Constants
  static const String splash = '/splash';
  static const String language = '/language';
  static const String authMain = '/auth_main';
  static const String login = '/login';
  static const String register = '/register';
  static const String dashboard = '/dashboard'; // Contains bottom nav
  static const String vitalSignsHome = '/vital_signs_home';
  static const String measurementInstruction = '/measurement_instruction';
  static const String measurementMeasuring = '/measurement_measuring';
  static const String measurementResult = '/measurement_result';
  static const String history = '/history';
  static const String clinic = '';
  static const String diseasDiagnoses = '/diagnoses';
  static const String diagnosisDuration = '/diagnoses/duration';
  static const String diagnosisLoading = '/diagnoses/loading';
  static const String diagnosisResults = '/diagnoses/results';
  static const String diagnosisRecommendations = '/diagnoses/recommendations';
  static const String aiInterview = '/diagnoses/ai_interview'; // NEW ROUTE

  static const String medicalHistoryList = '/medical_history_list';
  static const String clinicsList = '/clinics';
  static const String clinicRequirements = '/clinics/requirements';
  static const String measurementsTable = '/measurements_table';

  static const String scannerHome = '/scanner';
  static const String scannerProgress = '/scanner/progress';
  static const String scannerResults = '/scanner/results';

  static Route<dynamic> _buildPageRoute(Widget page, RouteSettings settings) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(1.0, 0.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 300),
    );
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return _buildPageRoute(const SplashScreen(), settings);
      
      case language:
        return _buildPageRoute(const LanguageSelectionScreen(), settings);
      
      case authMain:
        return _buildPageRoute(const AuthMainScreen(), settings);
        
      case login:
        return _buildPageRoute(const LoginScreen(), settings);
        
      case register:
        return _buildPageRoute(const RegisterScreen(), settings);
        
      case dashboard:
        return _buildPageRoute(const MainShell(), settings);

      case vitalSignsHome:
        return _buildPageRoute(const VitalSignsScreen(), settings);

      case measurementInstruction:
        final args = settings.arguments;
        if (args is MeasurementType) {
          return _buildPageRoute(
            MeasurementInstructionScreen(type: args), settings
          );
        } else if (args is Map<String, dynamic>) {
          return _buildPageRoute(
            MeasurementInstructionScreen(
              type: args['type'] as MeasurementType,
              remainingTypes: args['remainingTypes'] as List<MeasurementType>?,
            ), settings
          );
        }
        return _buildPageRoute(
          const Scaffold(body: Center(child: Text('Invalid arguments for measurementInstruction'))), settings
        );

      case measurementMeasuring:
        final args = settings.arguments;
        if (args is MeasurementType) {
          return _buildPageRoute(
            MeasurementMeasuringScreen(type: args), settings
          );
        } else if (args is Map<String, dynamic>) {
          return _buildPageRoute(
            MeasurementMeasuringScreen(
              type: args['type'] as MeasurementType,
              remainingTypes: args['remainingTypes'] as List<MeasurementType>?,
            ), settings
          );
        }
        return _buildPageRoute(
          const Scaffold(body: Center(child: Text('Invalid arguments for measurementMeasuring'))), settings
        );

      case measurementResult:
        final args = settings.arguments as Map<String, dynamic>?;
        final type = args?['type'] as MeasurementType?;
        final resultData = args?['resultData'] as Map<String, dynamic>?;
        return _buildPageRoute(
          MeasurementResultScreen(
            type: type,
            resultData: resultData,
          ), settings
        );

      case history:
        return _buildPageRoute(const MedicalRecordScreen(), settings);

      case diseasDiagnoses:
        return _buildPageRoute(const DiagnosisHomeScreen(), settings);
      
      case aiInterview:
        return _buildPageRoute(const AiInterviewScreen(), settings);
      
      case diagnosisDuration:
        return _buildPageRoute(const DiagnosisDurationScreen(), settings);
      
      case diagnosisLoading:
        return _buildPageRoute(const DiagnosisLoadingScreen(), settings);

      case diagnosisResults:
        return _buildPageRoute(const DiagnosisResultsScreen(), settings);

      case diagnosisRecommendations:
        return _buildPageRoute(const DiagnosisRecommendationsScreen(), settings);

      case medicalHistoryList:
        return _buildPageRoute(const MedicalHistoryScreen(), settings);

      case clinicsList:
        return _buildPageRoute(const ClinicsScreen(), settings);

      case clinicRequirements:
        return _buildPageRoute(const ClinicRequirementsScreen(), settings);

      case measurementsTable:
        return _buildPageRoute(const MeasurementsTableScreen(), settings);

      case scannerHome:
        return _buildPageRoute(const ScannerHomeScreen(), settings);

      case scannerProgress:
        return _buildPageRoute(const ScannerProgressScreen(), settings);

      case scannerResults:
        return _buildPageRoute(const ScannerResultsScreen(), settings);

      default:
        // Fallback route for undefined paths
        return _buildPageRoute(
          Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ), settings
        );
    }
  }
}
