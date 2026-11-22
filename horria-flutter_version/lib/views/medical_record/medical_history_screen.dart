import 'package:flutter/material.dart';


class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({super.key});

  Widget _buildHistoryItem(String title, String date, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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

  @override
  Widget build(BuildContext context) {
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
                    // Back Button
                    InkWell(
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
                              fontSize: 18,
                              color: Color(0xFF65418F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(
                            Icons.arrow_forward,
                            color: Color(0xFF65418F),
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    const Text(
                      'التاريخ المرضي',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF65418F),
                      ),
                    ),
                    const SizedBox(height: 30),

                    // History List
                    Expanded(
                      child: ListView(
                        children: [
                          _buildHistoryItem(
                            'زيارة طوارئ',
                            'يناير 2026',
                            'ارتفاع مفاجئ في الضغط — ١٧٠/١٠٥. تم وصف أدوية فورية.',
                          ),
                          _buildHistoryItem(
                            'أمراض قلب',
                            'مارس 2025',
                            'تشخيص ارتفاع ضغط الدم — بداية العلاج.',
                          ),
                          _buildHistoryItem(
                            'زيارة طوارئ',
                            'يناير 2026',
                            'ارتفاع مفاجئ في الضغط — ١٧٠/١٠٥. تم وصف أدوية فورية.',
                          ),
                          _buildHistoryItem(
                            'زيارة طوارئ',
                            'يناير 2026',
                            'ارتفاع مفاجئ في الضغط — ١٧٠/١٠٥. تم وصف أدوية فورية.',
                          ),
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
