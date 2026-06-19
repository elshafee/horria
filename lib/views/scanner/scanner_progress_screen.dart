import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../diagnosis/diagnosis_layout.dart';

class ScannerProgressScreen extends StatefulWidget {
  const ScannerProgressScreen({super.key});

  @override
  State<ScannerProgressScreen> createState() => _ScannerProgressScreenState();
}

class _ScannerProgressScreenState extends State<ScannerProgressScreen> {
  int _progress = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() {
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (_progress >= 100) {
        timer.cancel();
      } else {
        setState(() {
          _progress++;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildStepRow(String title, String subtitle, bool isCompleted, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFDE8ED).withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted ? const Color(0xFFFF85A1) : Colors.white,
              border: isCompleted ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: isCompleted
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
          
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black54, fontSize: 14),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65418F),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: const Color(0xFFFF85A1), size: 20),
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
    final bool isDone = _progress == 100;

    return DiagnosisLayout(
      title: 'الماسح الطبي',
      robotMessage: isDone 
          ? 'حورية تقرأ الروشتة'
          : 'الرجاء الانتظار — الماسح يقرأ المحتوى',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isDone 
                    ? 'تم اكتشاف مستند طبي'
                    : 'جارِ المسح ... لا تُزل المستند — الجهاز يقرأ الآن',
                style: const TextStyle(
                  fontSize: 18,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Circular Progress
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 180,
                    height: 180,
                    child: CircularProgressIndicator(
                      value: _progress / 100,
                      strokeWidth: 20,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFD6C8E3)),
                    ),
                  ),
                  Text(
                    '$_progress%',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF7A28CB), // Deep purple
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (isDone)
              const Text(
                'يتم التعرف على الأدوية والجرعات والتحقق من التفاعلات الدوائية',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF65418F),
                ),
              )
            else
              const Text(
                'يتم مسح المستند',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF65418F),
                ),
              ),
              
            const SizedBox(height: 24),
            
            Expanded(
              child: ListView(
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStepRow(
                    'اكتشاف المستند',
                    '( جارِ استخراج النصوص من المستند )',
                    _progress > 30,
                    Icons.document_scanner_outlined,
                  ),
                  _buildStepRow(
                    'قراءة النص الطبي',
                    '( جارِ فهم وتحليل المعلومات الطبية )',
                    _progress > 60,
                    Icons.text_snippet_outlined,
                  ),
                  _buildStepRow(
                    'تجهيز النتائج',
                    '( جارِ تجهيز التفسير والتوصيات )',
                    _progress >= 100,
                    Icons.analytics_outlined,
                  ),
                ],
              ),
            ),
            
            if (isDone)
              Padding(
                padding: const EdgeInsets.only(top: 20, bottom: 20),
                child: SizedBox(
                  width: 300,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamed(context, AppRouter.scannerResults);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF563B7E), // Deep purple
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'عرض النتائج',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
