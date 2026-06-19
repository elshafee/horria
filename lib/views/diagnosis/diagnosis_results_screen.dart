import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../models/diagnosis_result.dart';
import 'diagnosis_layout.dart';

class DiagnosisResultsScreen extends StatelessWidget {
  const DiagnosisResultsScreen({super.key});

  Widget _buildResultCard({
    required DiagnosisResult result,
    required Color color,
    required bool isTop,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isTop ? const Color(0xFFFDE8ED).withOpacity(0.4) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTop ? const Color(0xFFFF85A1) : Colors.grey.withOpacity(0.15),
            width: isTop ? 2 : 1,
          ),
          boxShadow: [
            if (!isTop)
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF65418F),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF1EEF5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                result.probabilityText,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF65418F),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Row(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1EEF5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Container(
                            height: 8,
                            width: constraints.maxWidth * (result.percentage / 100),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${result.percentage}٪',
                  textDirection: TextDirection.ltr,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const Spacer(),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.symptoms.map((s) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withOpacity(0.2)),
                ),
                child: Text(
                  s,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final report = ModalRoute.of(context)?.settings.arguments as DiagnosisReport?;
    
    if (report == null) {
      return const Scaffold(body: Center(child: Text('Error: No report data')));
    }

    return DiagnosisLayout(
      title: 'نتائج التشخيص',
      robotMessage: report.robotMessage,
      showBackButton: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'حللت الأعراض .. وجدت ٣ احتمالات مرتبة من الأعلى للأقل. تذكر هذا ليس بديلاً عن الطبيب.',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF65418F),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
            
            Expanded(
              child: Row(
                children: report.results.asMap().entries.map((entry) {
                  int idx = entry.key;
                  DiagnosisResult result = entry.value;
                  return _buildResultCard(
                    result: result,
                    color: idx == 0 ? const Color(0xFFFF85A1) : const Color(0xFF65418F),
                    isTop: idx == 0,
                  );
                }).toList(),
              ),
            ),
            
            const SizedBox(height: 30),
            
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context, 
                      AppRouter.diagnosisRecommendations,
                      arguments: report.results.isNotEmpty ? report.results.first : null,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65418F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'اعرض التوصيات',
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
