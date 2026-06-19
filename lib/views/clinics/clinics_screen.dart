import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../models/measurement_type.dart';

class ClinicsScreen extends StatefulWidget {
  const ClinicsScreen({super.key});

  @override
  State<ClinicsScreen> createState() => _ClinicsScreenState();
}

class _ClinicsScreenState extends State<ClinicsScreen> {
  int? _selectedClinicIndex;

  final List<Map<String, dynamic>> _clinics = [
    {
      'title': 'الأمراض الصدرية والجهاز التنفسي',
      'schedule': 'المواعيد : من الأحد إلى الخميس ٩ ص : ٩ م',
      'icon': Icons.co2,
      'available': false,
      'requirements': [
        MeasurementType.oxygen,
        MeasurementType.temperature,
        MeasurementType.heartRate,
      ],
    },
    {
      'title': 'أمراض القلب والأوعية الدموية',
      'schedule': 'المواعيد : من الأحد إلى الخميس ٩ ص : ٩ م',
      'icon': Icons.favorite_border,
      'available': true,
      'requirements': [
        MeasurementType.bloodPressure,
        MeasurementType.ecg,
        MeasurementType.heartRate,
        MeasurementType.oxygen,
      ],
    },
    {
      'title': 'الأمراض الباطنية وضغط الدم',
      'schedule': 'المواعيد : من الأحد إلى الخميس ٩ ص : ٩ م',
      'icon': Icons.local_hospital_outlined,
      'available': true,
      'requirements': [
        MeasurementType.bloodPressure,
        MeasurementType.glucose,
        MeasurementType.temperature,
      ],
    },
    {
      'title': 'الطب العام وطب الأسرة',
      'schedule': 'المواعيد : من الأحد إلى الخميس ٩ ص : ٩ م',
      'icon': Icons.family_restroom,
      'available': false,
      'requirements': [
        MeasurementType.bloodPressure,
        MeasurementType.heartRate,
        MeasurementType.temperature,
      ],
    },
  ];

  void _onNext() {
    if (_selectedClinicIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار العيادة للمتابعة.',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    Navigator.pushNamed(
      context, 
      AppRouter.clinicRequirements,
      arguments: _clinics[_selectedClinicIndex!],
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

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      body: Stack(
        children: [
          // Background Waves
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
                    const SizedBox(height: 40), // Pushes the header and content down
                    // Header Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'العيادات',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF65418F),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'اختر العيادة المناسبة لحالتك الصحية',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
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
                    
                    // Back Button on Top Right above header theoretically, but we put it inline
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
                    const SizedBox(height: 30),

                    // Clinics Grid
                    Expanded(
                      child: GridView.builder(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemCount: _clinics.length,
                        itemBuilder: (context, index) {
                          final clinic = _clinics[index];
                          final isSelected = _selectedClinicIndex == index;
                          final isAvailable = clinic['available'] as bool;
                          
                          return InkWell(
                            onTap: () {
                              setState(() {
                                _selectedClinicIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isSelected ? const Color(0xFFFDE8ED).withOpacity(0.3) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? const Color(0xFFFF85A1) : Colors.grey.withOpacity(0.15),
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  if (!isSelected)
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.02),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          clinic['icon'],
                                          size: 24,
                                          color: const Color(0xFF65418F),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          clinic['title'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF65418F),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          clinic['schedule'],
                                          textAlign: TextAlign.center,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isAvailable)
                                    Positioned(
                                      top: -4,
                                      left: -4,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF1EEF5),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Text(
                                          'متاح',
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF65418F),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    
                    // Bottom Button
                    Align(
                      alignment: Alignment.center,
                      child: SizedBox(
                        width: 400,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: _onNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF65418F),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'التالي - متطلبات العيادة',
                            style: TextStyle(
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
