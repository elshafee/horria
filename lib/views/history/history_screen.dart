import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/theme/robot_theme.dart';
import '../../presentation/global_widgets/sdui_header_banner.dart';
import '../../core/network/vitals_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  int _selectedDayIndex = 3; // Demo
  
  Future<List<Map<String, dynamic>>>? _historyFuture;

  @override
  void initState() {
    super.initState();
    _historyFuture = VitalsService().getHistory();
  }

  String _formatDate(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr);
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4294);
    const lightPurple = Color(0xFFF9F7FA);

    return Scaffold(
      backgroundColor: lightPurple,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SduiHeaderBanner(
                title: AppStrings.dataLog,
                onBack: () => Navigator.pop(context),
                titleColor: RobotTheme.primaryPurple,
              ),
            ),

            // Date Selector (Horizontal Scroll)
            Container(
              height: 100,
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                reverse: true, // Right to left scrolling
                itemCount: 14, // Two weeks for demo
                itemBuilder: (context, index) {
                  final day = 16 - index; // Demo dates starting from 16
                  final isSelected = index == _selectedDayIndex;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDayIndex = index),
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryColor : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'نوفمبر',
                            style: TextStyle(
                              fontSize: 14,
                              color: isSelected ? Colors.white70 : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            day > 0 ? day.toString() : '1',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            // Selected Date Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                '16 نوفمبر 2023',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: primaryColor,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Data Table
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Table Header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(
                              'مؤشر القياس',
                              textAlign: TextAlign.right,
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'الوقت',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'النتيجة',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              'الحالة',
                              textAlign: TextAlign.left,
                              style: TextStyle(fontWeight: FontWeight.bold, color: primaryColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Table Rows
                    Expanded(
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: _historyFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('خطأ: ${snapshot.error}'));
                          }
                          
                          final records = snapshot.data ?? [];
                          if (records.isEmpty) {
                            return const Center(child: Text('لا توجد بيانات متاحة.'));
                          }

                          return ListView.builder(
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              final timeStr = _formatTime(record['timestamp']);
                              final dateStr = _formatDate(record['timestamp']);
                              final isCritical = record['is_critical'] == 1;

                              List<Widget> metrics = [];
                              
                              if (record['hr'] != null) {
                                metrics.add(_buildTableRow(
                                  icon: Icons.favorite,
                                  name: 'نبض القلب',
                                  time: '$dateStr $timeStr',
                                  result: record['hr'].toString(),
                                  unit: 'bpm',
                                  status: isCritical ? 'تنبيه' : 'طبيعي',
                                  isNormal: !isCritical,
                                ));
                                metrics.add(const Divider(height: 1, color: Colors.black12));
                              }
                              
                              if (record['sys'] != null && record['dia'] != null) {
                                metrics.add(_buildTableRow(
                                  icon: Icons.monitor_heart,
                                  name: 'ضغط الدم',
                                  time: '$dateStr $timeStr',
                                  result: '${record['sys']}/${record['dia']}',
                                  unit: 'mmHg',
                                  status: isCritical ? 'تنبيه' : 'طبيعي',
                                  isNormal: !isCritical,
                                ));
                                metrics.add(const Divider(height: 1, color: Colors.black12));
                              }
                              
                              if (record['spo2'] != null) {
                                metrics.add(_buildTableRow(
                                  icon: Icons.air,
                                  name: 'الأكسجين',
                                  time: '$dateStr $timeStr',
                                  result: record['spo2'].toString(),
                                  unit: '%',
                                  status: isCritical ? 'تنبيه' : 'طبيعي',
                                  isNormal: !isCritical,
                                ));
                                metrics.add(const Divider(height: 1, color: Colors.black12));
                              }
                              
                              if (record['temp'] != null) {
                                metrics.add(_buildTableRow(
                                  icon: Icons.thermostat,
                                  name: 'الحرارة',
                                  time: '$dateStr $timeStr',
                                  result: record['temp'].toString(),
                                  unit: '°C',
                                  status: isCritical ? 'تنبيه' : 'طبيعي',
                                  isNormal: !isCritical,
                                ));
                                metrics.add(const Divider(height: 1, color: Colors.black12));
                              }

                              return Column(children: metrics);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow({
    required IconData icon,
    required String name,
    required String time,
    required String result,
    required String unit,
    required String status,
    required bool isNormal,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          // Measurement Indicator
          Expanded(
            flex: 2,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E5F5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: const Color(0xFF6A4294), size: 20),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          
          // Time
          Expanded(
            flex: 1,
            child: Text(
              time,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          
          // Result
          Expanded(
            flex: 2,
            child: RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$result ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.black87,
                    ),
                  ),
                  TextSpan(
                    text: unit,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          // Status
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              decoration: BoxDecoration(
                color: isNormal ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                status,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isNormal ? Colors.green.shade700 : Colors.red.shade700,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
