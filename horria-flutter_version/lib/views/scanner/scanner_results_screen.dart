import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../diagnosis/diagnosis_layout.dart';
import 'package:intl/intl.dart' hide TextDirection;

class ScannerResultsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> results;

  const ScannerResultsScreen({super.key, required this.results});

  Widget _buildResultRow(String testName, String value, String category) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.15)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDE8ED),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: Color(0xFF65418F),
                fontWeight: FontWeight.bold,
              ),
              textDirection: TextDirection.ltr,
            ),
          ),
          
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                category,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 15,
                ),
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          
          Expanded(
            child: Text(
              testName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF65418F),
                fontSize: 16,
              ),
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = DateFormat('dd MMMM yyyy').format(now);

    return DiagnosisLayout(
      title: 'الماسح الطبي / نتيجة التحاليل',
      robotMessage: 'تم تحليل النتائج المعملية بنجاح — راجع التفاصيل',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            // Top Document Metadata Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF9F4FA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFFDE8ED)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.withOpacity(0.2)),
                        ),
                        child: const Icon(Icons.receipt_long, color: Colors.grey),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'نتائج معملية . $dateStr',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFFDE8ED)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.biotech, color: Color(0xFFFF85A1), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${results.length} مؤشرات حيوية',
                          style: const TextStyle(
                            color: Color(0xFF65418F),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Extracted Results List
            Expanded(
              child: results.isEmpty 
                ? const Center(
                    child: Text(
                      'لم يتم العثور على أية تحاليل واضحة',
                      style: TextStyle(fontSize: 18, color: Colors.black54),
                    ),
                  )
                : ListView.builder(
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final item = results[index];
                      final testName = item['test_name']?.toString() ?? 'تحليل غير معروف';
                      final value = item['value']?.toString() ?? '-';
                      final category = item['flag']?.toString() ?? 'معلومات عامة';
                      return _buildResultRow(testName, category, value); // Using category field as placeholder for now
                    },
                  ),
            ),
            
            const SizedBox(height: 16),
            
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  height: 56,
                  width: 200,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        AppRouter.medicalHistoryList,
                        (route) => route.settings.name == AppRouter.dashboard,
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFF65418F), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'حفظ في السجل الطبي',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF65418F),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                SizedBox(
                  height: 56,
                  width: 200,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRouter.scannerHome);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF563B7E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'مسح مستند جديد',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
