import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../models/diagnosis_result.dart';
import '../../models/measurement_type.dart';
import '../../core/network/auth_store.dart';
import '../../core/network/api_config.dart';
import 'diagnosis_layout.dart';

class DiagnosisLoadingScreen extends StatefulWidget {
  const DiagnosisLoadingScreen({super.key});

  @override
  State<DiagnosisLoadingScreen> createState() => _DiagnosisLoadingScreenState();
}

class _DiagnosisLoadingScreenState extends State<DiagnosisLoadingScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _performDiagnosis();
  }

  Future<void> _performDiagnosis() async {
    // Small artificial delay for animation smoothness
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
    final symptoms = args?['symptoms'] as List<String>? ?? [];
    final duration = args?['duration'] as String? ?? '';

    final userId = AuthStore().userId;
    final sessionId = AuthStore().sessionId;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 20);
    
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/diagnosis/analyze');
      final request = await client.postUrl(uri);
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      
      final payload = {
        'user_id': userId,
        'session_id': sessionId,
        'symptoms': symptoms,
        'duration': duration,
      };
      
      request.add(utf8.encode(jsonEncode(payload)));
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final data = jsonDecode(responseBody);
        final report = DiagnosisReport.fromMap(data);
        
        if (mounted) {
          Navigator.pushReplacementNamed(
            context, 
            AppRouter.diagnosisResults,
            arguments: report,
          );
        }
        return;
      }
    } catch (e) {
      debugPrint("Diagnosis API error: $e");
    } finally {
      client.close();
    }

    // Fallback to Mock if API fails or is not ready
    if (mounted) {
      _useMockFallback();
    }
  }

  void _useMockFallback() {
    final mockReport = DiagnosisReport(
      robotMessage: 'بناءً على أعراضك، هذه أقرب الاحتمالات (وضع المحاكاة)',
      results: [
        DiagnosisResult(
          title: 'نزلة برد أو إنفلونزا',
          probabilityText: 'احتمالية عالية',
          percentage: 82,
          symptoms: ['حمى', 'سعال', 'إرهاق', 'صداع'],
          recommendations: [
            Recommendation(
              title: 'قياسات مطلوبة',
              type: RecommendationType.measurements,
              items: ['درجة الحرارة', 'ضغط الدم', 'نسبة الأكسجين في الدم', 'معدل نبضات القلب'],
              requiredMeasurements: [
                MeasurementType.temperature,
                MeasurementType.bloodPressure,
                MeasurementType.oxygen,
                MeasurementType.heartRate,
              ],
            ),
            Recommendation(
              title: 'تحاليل دم مقترحة',
              type: RecommendationType.labTests,
              items: ['ESR', 'Ferritin', 'CRP', 'CBC'],
            ),
            Recommendation(
              title: 'العيادات',
              type: RecommendationType.clinic,
              items: ['عيادة الباطنة'],
            ),
          ],
        ),
        DiagnosisResult(
          title: 'التهاب الجيوب الأنفية',
          probabilityText: 'احتمالية متوسطة',
          percentage: 55,
          symptoms: ['احتقان', 'صداع', 'ألم وجه'],
        ),
      ],
    );

    Navigator.pushReplacementNamed(
      context, 
      AppRouter.diagnosisResults,
      arguments: mockReport,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiagnosisLayout(
      title: 'تشخيص الأمراض',
      robotMessage: 'يرجى الانتظار',
      showBackButton: false,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'جاري تحليل حالتك الصحية ...',
              style: TextStyle(
                fontSize: 24,
                color: Color(0xFF65418F),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 40),
            
            // Animated dots
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(4, (index) {
                    final delay = index * 0.2;
                    final progress = (_controller.value - delay).clamp(0.0, 1.0);
                    final double opacity = progress < 0.5 ? progress * 2 : (1 - progress) * 2;
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Container(
                        width: 15,
                        height: 15,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF85A1).withOpacity(opacity.clamp(0.2, 1.0)),
                          shape: BoxShape.circle,
                        ),
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
