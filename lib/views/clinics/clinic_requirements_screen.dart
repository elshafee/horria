import 'package:flutter/material.dart';
import '../../models/measurement_type.dart';
import '../measurements/measurement_popup_dialog.dart';
import '../../data/measurement_store.dart';

import '../../core/network/vitals_service.dart';

class ClinicRequirementsScreen extends StatefulWidget {
  const ClinicRequirementsScreen({super.key});

  @override
  State<ClinicRequirementsScreen> createState() => _ClinicRequirementsScreenState();
}

class _ClinicRequirementsScreenState extends State<ClinicRequirementsScreen> {
  late Map<String, dynamic> _clinicData;
  late List<MeasurementType> _requirements;
  
  final Map<MeasurementType, bool> _completed = {};
  final Map<MeasurementType, String> _results = {};

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map<String, dynamic>) {
        _clinicData = args;
        _requirements = (_clinicData['requirements'] as List<dynamic>?)?.cast<MeasurementType>() ?? [];
        
        // Initialize state maps
        for (var req in _requirements) {
          _completed[req] = false;
          _results[req] = 'لم يتم القياس بعد';
        }
      } else {
        _clinicData = {'title': 'العيادة'};
        _requirements = [];
      }
      _initialized = true;
    }
  }

  Future<void> _startMeasurementsFlow() async {
    for (var req in _requirements) {
      if (_completed[req] == true) continue; // Skip already done

      final bool? success = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => MeasurementPopupDialog(type: req),
      );

      if (success == true) {
        // Measurement succeeded, update state
        setState(() {
          _completed[req] = true;
          
          // Try to fetch latest value from store to show
          final data = MeasurementStore().getMeasurement(req);
          if (data.value != '--' && data.value != '--/--') {
            _results[req] = '${data.value} ${data.unit}';
          } else {
            _results[req] = 'تم القياس';
          }
        });
      } else {
        // User closed dialog or failed. Stop sequence.
        break;
      }
    }

    // After loop, check if all done
    if (_requirements.isNotEmpty && _completed.values.every((v) => v == true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم اكتمال جميع القياسات. جاري الطباعة...', textDirection: TextDirection.rtl)),
      );
      try {
        await VitalsService().printAssessment(clinicName: _clinicData['title']);
      } catch (e) {
        debugPrint("Error printing: $e");
      }
    }
  }

  IconData _getIconForMeasurement(MeasurementType type) {
    switch (type) {
      case MeasurementType.bloodPressure: return Icons.bloodtype;
      case MeasurementType.ecg: return Icons.monitor_heart;
      case MeasurementType.glucose: return Icons.opacity;
      case MeasurementType.heartRate: return Icons.favorite;
      case MeasurementType.oxygen: return Icons.water_drop_outlined;
      case MeasurementType.temperature: return Icons.thermostat;
    }
  }

  Widget _buildMeasurementRow({
    required String title,
    required IconData icon,
    required bool isDone,
    required String valueOrStatus,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDone ? const Color(0xFFFDE8ED).withOpacity(0.3) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDone ? const Color(0xFFFF85A1).withOpacity(0.3) : Colors.grey.withOpacity(0.15)),
        boxShadow: [
          if (!isDone)
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            height: 45,
            child: ElevatedButton(
              onPressed: isDone ? null : () {}, // Action is handled by main button or could launch single dialog here
              style: ElevatedButton.styleFrom(
                backgroundColor: isDone ? const Color(0xFFFF85A1) : const Color(0xFF65418F),
                disabledBackgroundColor: const Color(0xFFFF85A1).withOpacity(0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                isDone ? 'تم القياس' : 'مطلوب',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          if (isDone)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else
            Icon(Icons.pending_actions, color: Colors.grey.shade400, size: 28),
          Expanded(
            child: Text(
              valueOrStatus,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: isDone ? const Color(0xFF65418F) : Colors.grey.shade600,
                fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF65418F),
            ),
          ),
          const SizedBox(width: 16),
          Icon(icon, color: const Color(0xFFFF85A1), size: 28),
        ],
      ),
    );
  }

  String _getMonthName(int month) {
    const months = [
      'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
      'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateStr = '${now.day} ${_getMonthName(now.month)} ${now.year}';
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'م' : 'ص'}';

    bool allDone = _requirements.isNotEmpty && _completed.values.every((v) => v == true);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      body: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: -105,
            child: Opacity(
              opacity: 0.2,
              child: Image.asset(
                'assets/images/common/background.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SafeArea(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'العيادات > ${_clinicData['title']}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'اليوم: $dateStr | $timeStr',
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(Icons.calendar_today_outlined, color: Colors.pink.shade300, size: 20),
                          ],
                        ),
                      ],
                    ),
                    
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        onTap: () {
                          if (Navigator.canPop(context)) {
                            Navigator.pop(context);
                          }
                        },
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'رجوع',
                              style: TextStyle(
                                fontSize: 16,
                                color: Color(0xFF65418F),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 8),
                            Icon(
                              Icons.arrow_forward,
                              color: Color(0xFF65418F),
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'قبل زيارة العيادة يُرجى إتمام القياسات المطلوبة لتحسين دقة التقييم',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Measurements List
                    Expanded(
                      child: ListView.builder(
                        itemCount: _requirements.length,
                        itemBuilder: (context, index) {
                          final req = _requirements[index];
                          return _buildMeasurementRow(
                            title: req.title,
                            icon: _getIconForMeasurement(req),
                            isDone: _completed[req] ?? false,
                            valueOrStatus: _results[req] ?? '',
                          );
                        },
                      ),
                    ),
                    
                    // Warning Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDE8ED).withOpacity(0.4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFF85A1).withOpacity(0.3)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'يُنصح بإجراء القياسات قبل ٣٠ دقيقة من موعد العيادة للحصول على نتائج دقيقة. تأكد من الجلوس بهدوء قبل القياس.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF65418F),
                            ),
                          ),
                          SizedBox(width: 12),
                          Icon(Icons.info_outline, color: Color(0xFFFF85A1), size: 20),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Bottom Button
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 400,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: allDone ? null : _startMeasurementsFlow,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: allDone ? Colors.green : const Color(0xFF65418F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
                            allDone ? 'اكتملت جميع القياسات' : 'ابدأ القياسات',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
