import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../global_widgets/sdui_sidebar.dart';
import '../../dashboard/dashboard.dart';
import '../../vital sign/vital_sig_home.dart';
import '../../views/measurements/measurement_instruction_screen.dart';
import '../../views/measurements/measurement_measuring_screen.dart';
import '../../views/measurements/measurement_result_screen.dart';
import '../../views/history/history_screen.dart';
import '../../views/diagnosis/diagnosis_home_screen.dart';
import '../../views/diagnosis/diagnosis_duration_screen.dart';
import '../../views/diagnosis/diagnosis_loading_screen.dart';
import '../../views/diagnosis/diagnosis_results_screen.dart';
import '../../views/diagnosis/diagnosis_recommendations_screen.dart';
import '../../views/diagnosis/ai_interview_screen.dart';
import '../../views/medical_record/medical_record_screen.dart';
import '../../views/medical_record/medical_history_screen.dart';
import '../../views/clinics/clinics_screen.dart';
import '../../views/clinics/clinic_requirements_screen.dart';
import '../../views/measurements/measurements_table_screen.dart';
import '../../views/scanner/scanner_home_screen.dart';
import '../../views/scanner/scanner_progress_screen.dart';
import '../../views/scanner/scanner_results_screen.dart';
import '../../models/measurement_type.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<NavigatorState> _innerNavigatorKey = GlobalKey<NavigatorState>();
  int _selectedIndex = 0;

  // Map route names to sidebar indices
  final Map<String, int> _routeToIndex = {
    AppRouter.dashboard: 0,
    AppRouter.diseasDiagnoses: 1,
    AppRouter.aiInterview: 1,
    AppRouter.diagnosisDuration: 1,
    AppRouter.diagnosisLoading: 1,
    AppRouter.diagnosisResults: 1,
    AppRouter.diagnosisRecommendations: 1,
    AppRouter.history: 2,
    AppRouter.medicalHistoryList: 2,
    AppRouter.clinicsList: 2,
    AppRouter.clinicRequirements: 2,
    AppRouter.measurementsTable: 2,
    AppRouter.scannerHome: 1,
    AppRouter.scannerProgress: 1,
    AppRouter.scannerResults: 1,
  };

  void _onRouteChanged(String? routeName) {
    if (routeName != null && _routeToIndex.containsKey(routeName)) {
      setState(() {
        _selectedIndex = _routeToIndex[routeName]!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      body: Stack(
        children: [
          // Content Area - Background now extends under the sidebar
          Positioned.fill(
            child: Navigator(
              key: _innerNavigatorKey,
              initialRoute: AppRouter.dashboard,
              onGenerateRoute: (settings) {
                // Update sidebar index whenever a route is pushed
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _onRouteChanged(settings.name);
                });

                return PageRouteBuilder(
                  settings: settings,
                  pageBuilder: (context, animation, secondaryAnimation) {
                    Widget screen;
                    switch (settings.name) {
                      case AppRouter.dashboard:
                        screen = const HomeScreen();
                        break;
                      case AppRouter.vitalSignsHome:
                        screen = const VitalSignsScreen();
                        break;
                      case AppRouter.measurementInstruction:
                        MeasurementType type;
                        if (settings.arguments is Map) {
                          type = (settings.arguments as Map)['type'] as MeasurementType;
                        } else {
                          type = settings.arguments as MeasurementType;
                        }
                        screen = MeasurementInstructionScreen(type: type);
                        break;
                      case AppRouter.measurementMeasuring:
                        MeasurementType type;
                        if (settings.arguments is Map) {
                          type = (settings.arguments as Map)['type'] as MeasurementType;
                        } else {
                          type = settings.arguments as MeasurementType;
                        }
                        screen = MeasurementMeasuringScreen(type: type);
                        break;
                      case AppRouter.measurementResult:
                        final args = settings.arguments as Map<String, dynamic>?;
                        final type = args?['type'] as MeasurementType?;
                        final resultData = args?['resultData'] as Map<String, dynamic>?;
                        screen = MeasurementResultScreen(type: type, resultData: resultData);
                        break;
                      case AppRouter.history:
                        screen = const MedicalRecordScreen();
                        break;
                      case AppRouter.medicalHistoryList:
                        screen = const MedicalHistoryScreen();
                        break;
                      case AppRouter.clinicsList:
                        screen = const ClinicsScreen();
                        break;
                      case AppRouter.clinicRequirements:
                        screen = const ClinicRequirementsScreen();
                        break;
                      case AppRouter.measurementsTable:
                        screen = const MeasurementsTableScreen();
                        break;
                      case AppRouter.diseasDiagnoses:
                        screen = const DiagnosisHomeScreen();
                        break;
                      case AppRouter.aiInterview:
                        screen = const AiInterviewScreen();
                        break;
                      case AppRouter.scannerHome:
                        screen = const ScannerHomeScreen();
                        break;
                      case AppRouter.scannerProgress:
                        screen = const ScannerProgressScreen();
                        break;
                      case AppRouter.scannerResults:
                        screen = const ScannerResultsScreen();
                        break;
                      case AppRouter.diagnosisDuration:
                        screen = const DiagnosisDurationScreen();
                        break;
                      case AppRouter.diagnosisLoading:
                        screen = const DiagnosisLoadingScreen();
                        break;
                      case AppRouter.diagnosisResults:
                        screen = const DiagnosisResultsScreen();
                        break;
                      case AppRouter.diagnosisRecommendations:
                        screen = const DiagnosisRecommendationsScreen();
                        break;
                      default:
                        screen = const HomeScreen();
                    }

                    // Add right padding to all screens so content doesn't overlap the sidebar
                    return Padding(
                      padding: const EdgeInsets.only(right: 105),
                      child: screen,
                    );
                  },
                  transitionsBuilder: (context, animation, secondaryAnimation, child) {
                    return FadeTransition(
                      opacity: animation,
                      child: child,
                    );
                  },
                );
              },
            ),
          ),

          // Sidebar - Fixed on the right, layered on top to show background through rounded corners
          Positioned(
            top: 0,
            bottom: 0,
            right: 0,
            child: SduiSidebar(
              selectedIndex: _selectedIndex,
              onNavRequest: (route) {
                _innerNavigatorKey.currentState?.pushReplacementNamed(route);
              },
            ),
          ),
        ],
      ),
    );
  }
}
