import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../../core/network/user_service.dart';
import '../../data/measurement_store.dart';
import '../../models/measurement_type.dart';
import 'update_profile_dialog.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> {
  UserProfile? _profile;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    setState(() => _isLoading = true);
    final profile = await UserService().getUserProfile();
    if (mounted) {
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    }
  }

  void _showUpdateDialog() async {
    if (_profile == null) return;
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => UpdateProfileDialog(profile: _profile!),
    );
    if (result == true) {
      _fetchProfile(); // Refresh after update
    }
  }

  Widget _buildVitalCard(String title, String value, String unit, IconData icon, Color iconColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      TextSpan(
                        text: ' $unit',
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
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFDE8ED).withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryItem(String title, String date, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF65418F),
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      margin: const EdgeInsets.only(left: 8, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFFFF85A1), size: 16),
          const SizedBox(width: 4),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
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
    
    // Live Vitals
    final hrData = MeasurementStore().getMeasurement(MeasurementType.heartRate);
    final bpData = MeasurementStore().getMeasurement(MeasurementType.bloodPressure);
    final tempData = MeasurementStore().getMeasurement(MeasurementType.temperature);

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
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'السجل الطبي',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),
                        Row(
                          children: [
                            Text(
                              'تاريخ اليوم | $dateStr',
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
                    const SizedBox(height: 24),

                    // Profile Card
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (_profile != null)
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFF65418F),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF85A1),
                                shape: BoxShape.circle,
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _profile!.name.isNotEmpty ? _profile!.name[0] : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile!.name,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_profile!.age} سنة · ${_profile!.gender == 'male' ? 'ذكر' : 'أنثى'} · الرقم الطبي: #MED-${_profile!.id.toString().padLeft(5, '0')}',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    children: [
                                      if (_profile!.medicalHistory['blood_type']?.isNotEmpty ?? false)
                                        _buildTag('فصيلة الدم: ${_profile!.medicalHistory['blood_type']}'),
                                      if (_profile!.medicalHistory['weight']?.isNotEmpty ?? false)
                                        _buildTag('الوزن: ${_profile!.medicalHistory['weight']} كجم'),
                                      if (_profile!.medicalHistory['height']?.isNotEmpty ?? false)
                                        _buildTag('الطول: ${_profile!.medicalHistory['height']} سم'),
                                      if (_profile!.medicalHistory['conditions']?.isNotEmpty ?? false)
                                        _buildTag('أمراض: ${_profile!.medicalHistory['conditions']}'),
                                      if (_profile!.medicalHistory['allergies']?.isNotEmpty ?? false)
                                        _buildTag('حساسية: ${_profile!.medicalHistory['allergies']}'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            OutlinedButton(
                              onPressed: _showUpdateDialog,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.white),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                              ),
                              child: const Text(
                                'تحديث البيانات',
                                style: TextStyle(color: Colors.white, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Middle Row: Vitals + All Measurements Button
                    Row(
                      children: [
                        _buildVitalCard('آخر نبض', hrData.value == '--' ? '--' : hrData.value, hrData.unit, Icons.favorite_border, const Color(0xFFFF85A1)),
                        _buildVitalCard('آخر ضغط', bpData.value == '--/--' ? '--' : bpData.value, bpData.unit, Icons.monitor_heart, const Color(0xFFFF85A1)),
                        _buildVitalCard('آخر حرارة', tempData.value == '--' ? '--' : tempData.value, tempData.unit, Icons.thermostat, const Color(0xFFFF85A1)),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              Navigator.pushNamed(context, AppRouter.measurementsTable);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 32),
                              decoration: BoxDecoration(
                                color: const Color(0xFF65418F),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              alignment: Alignment.center,
                              child: const Text(
                                'جميع القياسات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    // History Section Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'التاريخ المرضي',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.medicalHistoryList);
                          },
                          child: const Text(
                            'الكل',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF65418F),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // History List Preview
                    Expanded(
                      child: ListView(
                        children: [
                          if (_profile?.medicalHistory.isEmpty ?? true)
                            const Padding(
                              padding: EdgeInsets.all(32.0),
                              child: Text(
                                'لا توجد سجلات حالية.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            ),
                          ...(_profile?.medicalHistory.entries
                                  .where((e) => !['weight', 'height', 'conditions', 'allergies'].contains(e.key))
                                  .map((e) => _buildHistoryItem(
                                        'إجابة تاريخ طبي',
                                        dateStr,
                                        'سؤال ID: ${e.key}\nالإجابة: ${e.value}',
                                      )) ??
                              []),
                        ],
                      ),
                    ),
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
