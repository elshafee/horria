import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../diagnosis/diagnosis_layout.dart';

class ScannerResultsScreen extends StatelessWidget {
  const ScannerResultsScreen({super.key});

  Widget _buildMedicationRow(String name, String details, String frequency) {
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
              frequency,
              style: const TextStyle(
                color: Color(0xFF65418F),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          
          Text(
            details,
            style: const TextStyle(
              color: Colors.black54,
              fontSize: 15,
            ),
          ),
          
          Text(
            name,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF65418F),
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DiagnosisLayout(
      title: 'الماسح الطبي / نتيجة المسح',
      robotMessage: 'تم تحليل الروشتة بنجاح — راجع التفاصيل',
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
                      const Text(
                        'د. سارة أحمد . 13 يونيو 2026',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 16,
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
                    child: const Row(
                      children: [
                        Icon(Icons.medication, color: Color(0xFFFF85A1), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'روشتة طبية . 3 أدوية',
                          style: TextStyle(
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
            
            // Extracted Medications List
            Expanded(
              child: ListView(
                children: [
                  _buildMedicationRow(
                    'أموكسيسيلين 500 مجم',
                    '( كبسولة . بعد الأكل )',
                    '3x يومياً',
                  ),
                  _buildMedicationRow(
                    'أموكسيسيلين 500 مجم',
                    '( كبسولة . بعد الأكل )',
                    '3x يومياً',
                  ),
                  _buildMedicationRow(
                    'أموكسيسيلين 500 مجم',
                    '( كبسولة . بعد الأكل )',
                    '3x يومياً',
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Warning Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF0F0),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFFCDD2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(
                                fontFamily: 'Cairo', // Assuming Cairo or similar font
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              children: [
                                TextSpan(
                                  text: 'تنبيه : ',
                                  style: TextStyle(
                                    color: Colors.redAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                TextSpan(
                                  text: 'أموكسيسيلين من عائلة البنسلين — تأكد من عدم وجود حساسية مسجّلة.',
                                  style: TextStyle(
                                    color: Color(0xFF65418F),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
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
