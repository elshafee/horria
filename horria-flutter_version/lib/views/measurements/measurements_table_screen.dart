import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../data/measurement_store.dart';
import '../../models/measurement_type.dart';
import '../diagnosis/diagnosis_layout.dart';
import '../../core/network/vitals_service.dart';

class MeasurementsTableScreen extends StatelessWidget {
  const MeasurementsTableScreen({super.key});

  Widget _buildTableRow({
    required String indicator,
    required String result,
    required String unit,
    required String range,
    required String status,
    required String time,
    required IconData icon,
    bool isEven = false,
    bool isNormal = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      decoration: BoxDecoration(
        color: isEven ? const Color(0xFFF9F7FA).withOpacity(0.5) : Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.withOpacity(0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFFFF85A1), size: 20),
                const SizedBox(width: 10),
                Text(
                  indicator,
                  style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              result,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: isNormal ? const Color(0xFF65418F) : const Color(0xFFEB5757),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              unit,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              range,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: isNormal ? const Color(0xFFF1EEF5) : const Color(0xFFFCEBEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    color: isNormal ? const Color(0xFF65418F) : const Color(0xFFEB5757),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getIconForType(MeasurementType type) {
    switch (type) {
      case MeasurementType.glucose: return Icons.water_drop;
      case MeasurementType.ecg: return Icons.monitor_heart;
      case MeasurementType.bloodPressure: return Icons.bloodtype;
      case MeasurementType.oxygen: return Icons.water_drop_outlined;
      case MeasurementType.heartRate: return Icons.favorite_border;
      case MeasurementType.temperature: return Icons.thermostat;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = MeasurementStore();
    final measurements = store.getAllMeasurements();
    final allNormal = store.isAllNormal();
    final abnormalMetrics = store.getAbnormalMetrics();
    final latestUpdate = store.getLatestUpdateTime();
    final lastUpdateStr = MeasurementStore.formatDateArabic(latestUpdate);

    String robotMsg = 'جميع القياسات ضمن المعدل الطبيعي\nحالتك مستقرة - لا توجد مؤشرات غير طبيعية';
    if (!allNormal) {
      robotMsg = 'تنبيه: توجد بعض القياسات غير الطبيعية\nالمؤشرات: ${abnormalMetrics.join('، ')}';
    }

    return DiagnosisLayout(
      title: 'نتائج القياسات',
      robotMessage: robotMsg,
      showBackButton: false,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Expanded(
              child: Container(
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
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8ED).withOpacity(0.4),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('المؤشر', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          Expanded(flex: 1, child: Text('النتيجة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          Expanded(flex: 1, child: Text('الوحدة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          Expanded(flex: 2, child: Text('المدى الطبيعي', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          Expanded(flex: 1, child: Text('الحالة', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                          Expanded(flex: 1, child: Text('الوقت', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87))),
                        ],
                      ),
                    ),
                    
                    // Table Body
                    Expanded(
                      child: measurements.isEmpty 
                        ? const Center(child: Text('لا توجد قياسات مسجلة بعد'))
                        : ListView.builder(
                            itemCount: measurements.length,
                            itemBuilder: (context, index) {
                              final m = measurements[index];
                              return _buildTableRow(
                                indicator: m.title,
                                result: m.value,
                                unit: m.unit,
                                range: m.normalRange,
                                status: m.statusClass,
                                time: m.time,
                                icon: _getIconForType(m.type),
                                isEven: index % 2 != 0,
                                isNormal: m.isNormal,
                              );
                            },
                          ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Bottom Area
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: Colors.pinkAccent, size: 20),
                      Text(
                        'آخر تحديث: $lastUpdateStr',
                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.info_outline, color: Colors.grey.shade500, size: 20),
                      Text(
                        'هذه النتائج مخصصة للاسترشاد فقط ولا تغني عن استشارة الطبيب',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                
                Row(
                  children: [
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('جاري طباعة النتائج...', style: TextStyle(fontFamily: 'Cairo')),
                              duration: Duration(seconds: 2),
                            ),
                          );
                          
                          final success = await VitalsService().printAssessment();
                          
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success ? 'تم إرسال أمر الطباعة بنجاح' : 'فشل في الاتصال بالطابعة',
                                  style: const TextStyle(fontFamily: 'Cairo'),
                                ),
                                backgroundColor: success ? Colors.green : Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.print, color: Colors.white),
                        label: const Text(
                          'طباعة النتائج',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF65418F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 180,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.vitalSignsHome);
                        },
                        icon: const Icon(Icons.add, color: Colors.white),
                        label: const Text(
                          'قياس جديد',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF65418F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
              ],
            ),

        ),

    );
  }
}
