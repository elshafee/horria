import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../models/diagnosis_result.dart';
import '../../models/measurement_type.dart';
import 'diagnosis_layout.dart';

class DiagnosisRecommendationsScreen extends StatelessWidget {
  const DiagnosisRecommendationsScreen({super.key});

  Widget _buildRecommendationRow({
    required Recommendation recommendation,
    required String buttonText,
    required VoidCallback onPressed,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recommendation.title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65418F),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: recommendation.items.map((t) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1EEF5),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      t,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                      ),
                    ),
                  )).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 130,
            height: 45,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65418F),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startSequentialMeasurements(BuildContext context, List<MeasurementType> types) {
    if (types.isEmpty) return;

    final firstType = types.first;
    final remainingTypes = types.sublist(1);

    Navigator.pushNamed(
      context,
      AppRouter.measurementInstruction,
      arguments: {
        'type': firstType,
        'remainingTypes': remainingTypes,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = ModalRoute.of(context)?.settings.arguments as DiagnosisResult?;

    if (result == null) {
      return const Scaffold(body: Center(child: Text('Error: No result data')));
    }

    return DiagnosisLayout(
      title: 'التوصيات',
      robotMessage: 'بناءً على تشخيصك — ${result.title} (${result.percentage}٪)',
      showBackButton: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: result.recommendations.map((rec) {
                    if (rec.type == RecommendationType.clinic) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.withOpacity(0.15)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'العيادات',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF65418F),
                                ),
                              ),
                            ),
                            ...rec.items.map((item) => Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1EEF5),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                item,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF65418F),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )),
                            const SizedBox(width: 16),
                            SizedBox(
                              width: 130,
                              height: 45,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EEF5),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: const Text(
                                  'متاح الآن',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF65418F),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return _buildRecommendationRow(
                      recommendation: rec,
                      buttonText: rec.type == RecommendationType.measurements ? 'ابدأ القياس' : 'اطلب التحاليل',
                      onPressed: () {
                        if (rec.type == RecommendationType.measurements && rec.requiredMeasurements != null) {
                          _startSequentialMeasurements(context, rec.requiredMeasurements!);
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تنفيذ الإجراء: ${rec.title}')),
                          );
                        }
                      },
                    );
                  }).toList(),
                ),
              ),
            ),
            
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context, 
                      AppRouter.diseasDiagnoses, 
                      (route) => route.isFirst
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65418F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'تشخيص جديد',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
