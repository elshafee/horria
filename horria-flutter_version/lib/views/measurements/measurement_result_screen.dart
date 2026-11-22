import 'package:flutter/material.dart';
import '../../models/measurement_type.dart';
import '../../core/routes/app_router.dart';
import '../../data/measurement_store.dart';
import '../../core/network/vitals_service.dart';
import '../../ecg_painter.dart';
import 'measurement_layout.dart';

class MeasurementResultScreen extends StatelessWidget {
  final MeasurementType? type;
  final Map<String, dynamic>? resultData;

  const MeasurementResultScreen({
    super.key,
    this.type,
    this.resultData,
  });

  String _getIconPath(MeasurementType type) {
    switch (type) {
      case MeasurementType.glucose:
        return 'assets/images/measurements/icons/glucose.png';
      case MeasurementType.ecg:
        return 'assets/images/measurements/icons/ECG.png';
      case MeasurementType.bloodPressure:
        return 'assets/images/measurements/icons/blood_pressure.png';
      case MeasurementType.oxygen:
        return 'assets/images/measurements/icons/oxygen_level.png';
      case MeasurementType.heartRate:
        return 'assets/images/measurements/icons/heart_rate.png';
      case MeasurementType.temperature:
        return 'assets/images/measurements/icons/temperature.png';
    }
  }

  Widget _buildRobotCard(bool allNormal, List<String> abnormalMetrics) {
    final cardTitle = allNormal
        ? "جميع القياسات ضمن المعدل الطبيعي"
        : "تنبيه: توجد بعض القياسات غير الطبيعية";
    final cardSubtitle = allNormal
        ? "حالتك مستقرة - لا توجد مؤشرات غير طبيعية"
        : "المؤشرات غير الطبيعية: ${abnormalMetrics.join('، ')}";

    return SizedBox(
      height: 100,
      width: 480,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background card container
          Positioned(
            right: 0,
            left: 50, // Leave space for robot overlap on the left
            top: 10,
            bottom: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: allNormal
                      ? const Color(0xFFFF85A1).withOpacity(0.3)
                      : const Color(0xFFEB5757).withOpacity(0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                textDirection: TextDirection.rtl,
                children: [
                  // Checkmark or Warning Icon on the right
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: allNormal
                          ? const Color(0xFFFF85A1).withOpacity(0.1)
                          : const Color(0xFFEB5757).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      allNormal ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                      color: allNormal ? const Color(0xFFFF85A1) : const Color(0xFFEB5757),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Text column
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          cardTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: allNormal ? const Color(0xFF65418F) : const Color(0xFFEB5757),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardSubtitle,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Circular waves and Robot image on the left
          Positioned(
            left: 0,
            bottom: 0,
            top: -15, // Let it overlap vertically
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Concentric circles
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF85A1).withOpacity(0.08),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF85A1).withOpacity(0.15),
                      width: 1.5,
                    ),
                  ),
                ),
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFFF85A1).withOpacity(0.25),
                      width: 1.5,
                    ),
                  ),
                ),
                // Robot image
                Image.asset(
                  'assets/images/common/robot.png',
                  width: 70,
                  height: 70,
                  fit: BoxFit.contain,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: const BoxDecoration(
        color: Color(0xFFFBF4F6),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: const Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              'المؤشر',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'النتيجة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'الوحدة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'المدى الطبيعي',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'الحالة',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              'الوقت',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Color(0xFF2D2340),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(BuildContext context, MeasurementResultData data, bool isNewlyUpdated) {
    final row = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      decoration: BoxDecoration(
        color: isNewlyUpdated ? const Color(0xFFFF85A1).withOpacity(0.04) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.15),
            width: 1,
          ),
        ),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          // Indicator Name and Icon
          Expanded(
            flex: 3,
            child: Row(
              textDirection: TextDirection.rtl,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF85A1).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    _getIconPath(data.type),
                    width: 20,
                    height: 20,
                    color: const Color(0xFFFF85A1),
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.favorite,
                      size: 20,
                      color: Color(0xFFFF85A1),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  data.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D2340),
                  ),
                ),
                if (data.type == MeasurementType.ecg && data.ecgWavePoints != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF65418F).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.touch_app, size: 14, color: Color(0xFF65418F)),
                        SizedBox(width: 4),
                        Text('عرض التخطيط', style: TextStyle(fontSize: 11, color: Color(0xFF65418F), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          // Result Value
          Expanded(
            flex: 2,
            child: Text(
              data.value,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: data.isNormal ? const Color(0xFFFF85A1) : const Color(0xFFEB5757),
              ),
            ),
          ),
          // Unit
          Expanded(
            flex: 2,
            child: Text(
              data.unit,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),
          // Normal Range
          Expanded(
            flex: 2,
            child: Text(
              data.normalRange,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),
          // Status Badge
          Expanded(
            flex: 2,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: data.isNormal ? const Color(0xFFE2F6EC) : const Color(0xFFFCEBEC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  data.statusClass,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: data.isNormal ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                  ),
                ),
              ),
            ),
          ),
          // Time
          Expanded(
            flex: 2,
            child: Text(
              data.time,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ),
        ],
      ),
    );

    // Make ECG row tappable if wave data is available
    if (data.type == MeasurementType.ecg && data.ecgWavePoints != null && data.ecgWavePoints!.isNotEmpty) {
      return InkWell(
        onTap: () => _showEcgDialog(context, data),
        child: row,
      );
    }
    return row;
  }

  void _showEcgDialog(BuildContext context, MeasurementResultData data) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.6),
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 520),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.teal.withOpacity(0.3), width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00FF41).withOpacity(0.08),
                  blurRadius: 40,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.teal.withOpacity(0.2)),
                    ),
                  ),
                  child: Row(
                    textDirection: TextDirection.rtl,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00FF41).withOpacity(0.1),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF00FF41).withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.monitor_heart, color: Color(0xFF00FF41), size: 24),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'تخطيط القلب الكهربائي',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'ECG / Electrocardiogram',
                              style: TextStyle(fontSize: 13, color: Colors.white38),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close, color: Colors.white54),
                      ),
                    ],
                  ),
                ),

                // ECG Wave Preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF0A0F1A),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.teal.withOpacity(0.2)),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: CustomPaint(
                            size: Size(
                              (data.ecgWavePoints?.length ?? 0) * 1.5 < 500.0 
                                  ? 500.0 
                                  : (data.ecgWavePoints?.length ?? 0) * 1.5, 
                              double.infinity
                            ),
                            painter: EcgPainter(
                              dataPoints: data.ecgWavePoints ?? [],
                              gainScale: 120.0,
                              pixelsPerSample: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                // Info Chips Row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Directionality(
                    textDirection: TextDirection.rtl,
                    child: Row(
                      children: [
                        _buildEcgDetailChip(
                          icon: Icons.favorite,
                          label: 'معدل النبض',
                          value: '${data.value} bpm',
                          color: const Color(0xFFFF85A1),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildEcgDetailChip(
                            icon: Icons.analytics_outlined,
                            label: 'التشخيص',
                            value: data.ecgResultMessage ?? (data.isNormal ? 'طبيعي' : 'غير طبيعي'),
                            color: data.isNormal ? const Color(0xFF27AE60) : const Color(0xFFEB5757),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildEcgDetailChip(
                          icon: Icons.access_time,
                          label: 'وقت القياس',
                          value: data.time,
                          color: Colors.blueAccent,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Print Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text('جاري طباعة تخطيط القلب...', style: TextStyle(fontFamily: 'Cairo')),
                            duration: Duration(seconds: 2),
                          ),
                        );

                        final success = await VitalsService().printEcgStrip(
                          wavePoints: data.ecgWavePoints ?? [],
                          heartRate: int.tryParse(data.value),
                          diagnosis: data.ecgResultMessage,
                        );

                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
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
                        'طباعة تخطيط القلب',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF65418F),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEcgDetailChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 16),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, DateTime latestUpdate) {
    final lastUpdateStr = MeasurementStore.formatDateArabic(latestUpdate);

    return Row(
      textDirection: TextDirection.rtl,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left Side: Action Buttons
        Row(
          textDirection: TextDirection.rtl,
          children: [
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.vitalSignsHome,
                  (route) => false,
                );
              },
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                'قياس جديد',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65418F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
            const SizedBox(width: 12),
            ElevatedButton.icon(
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
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF65418F),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
            ),
          ],
        ),

        // Center: Info text with icon
        Row(
          textDirection: TextDirection.rtl,
          children: [
            Icon(
              Icons.info_outline,
              color: Colors.grey.shade500,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'هذه النتائج مخصصة للاسترشاد فقط ولا تغني عن استشارة الطبيب',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 14,
              ),
            ),
          ],
        ),

        // Right: Last updated timestamp
        Row(
          textDirection: TextDirection.rtl,
          children: [
            const Icon(
              Icons.calendar_month_outlined,
              color: Color(0xFFFF85A1),
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'آخر تحديث : $lastUpdateStr',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = MeasurementStore();
    final measurements = store.getAllMeasurements();
    final allNormal = store.isAllNormal();
    final abnormalMetrics = store.getAbnormalMetrics();
    final latestUpdate = store.getLatestUpdateTime();

    return MeasurementLayout(
      title: '', // Custom header layout inside child
      sidebarSelectedIndex: 1, // Highlight the Measurements tab
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Header Row (Title + Robot Greeting Card)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'نتائج القياسات',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65418F),
                  ),
                ),
                _buildRobotCard(allNormal, abnormalMetrics),
              ],
            ),
            const SizedBox(height: 24),

            // Results Table Container
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    _buildTableHeader(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: measurements.length,
                        itemBuilder: (context, index) {
                          final data = measurements[index];
                          final isNewlyUpdated = type != null && data.type == type;
                          return _buildTableRow(context, data, isNewlyUpdated);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Bottom Info and Action Row
            _buildBottomBar(context, latestUpdate),
          ],
        ),
      ),
    );
  }
}
