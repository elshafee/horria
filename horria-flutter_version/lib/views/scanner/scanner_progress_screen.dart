import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import '../diagnosis/diagnosis_layout.dart';
import '../../core/network/scanner_service.dart';

class ScannerProgressScreen extends StatefulWidget {
  const ScannerProgressScreen({super.key});

  @override
  State<ScannerProgressScreen> createState() => _ScannerProgressScreenState();
}

class _ScannerProgressScreenState extends State<ScannerProgressScreen> {
  int _progress = 0;
  Timer? _timer;
  
  bool _isScanApiDone = false;
  List<Map<String, dynamic>> _scanResults = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startScanning();
    _callScanApi();
  }

  void _startScanning() {
    // 350ms * 100 = 35 seconds total, which is much closer to the actual backend scan duration.
    _timer = Timer.periodic(const Duration(milliseconds: 350), (timer) {
      if (_progress >= 100) {
        timer.cancel();
      } else {
        // Pause at 99% if API is not done yet
        if (_progress == 99 && !_isScanApiDone) {
          return;
        }
        setState(() {
          _progress++;
        });
      }
    });
  }
  
  Future<void> _callScanApi() async {
    final service = ScannerService();
    final result = await service.scanLabResults();
    
    if (mounted) {
      setState(() {
        _isScanApiDone = true;
        if (result.isSuccess) {
          _scanResults = result.parsedResults;
        } else {
          _errorMessage = result.message;
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _buildStepRow(String title, String subtitle, bool isCompleted, IconData icon, {bool isError = false}) {
    final bool highlight = isCompleted || isError;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.withOpacity(0.1) : const Color(0xFFFDE8ED).withOpacity(0.3),
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
              color: isError ? Colors.red : (isCompleted ? const Color(0xFFFF85A1) : Colors.white),
              border: highlight ? null : Border.all(color: Colors.grey.shade300),
            ),
            child: isError 
                ? const Icon(Icons.close, color: Colors.white, size: 20)
                : (isCompleted ? const Icon(Icons.check, color: Colors.white, size: 20) : null),
          ),
          
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(color: isError ? Colors.red : Colors.black54, fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isError ? Colors.red : const Color(0xFF65418F),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 16),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isError ? Colors.red.withOpacity(0.1) : const Color(0xFFFDE8ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: isError ? Colors.red : const Color(0xFFFF85A1), size: 20),
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
    final bool isDone = _progress == 100 && _isScanApiDone;

    return DiagnosisLayout(
      title: 'الماسح الطبي',
      robotMessage: isDone 
          ? (_errorMessage != null ? 'حدث خطأ في القراءة' : 'حورية قرأت التحاليل بنجاح')
          : 'الرجاء الانتظار — الماسح يقرأ المحتوى',
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                isDone 
                    ? (_errorMessage != null ? 'فشل المسح' : 'تم استخراج نتائج التحاليل')
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
                      valueColor: AlwaysStoppedAnimation<Color>(_errorMessage != null ? Colors.red : const Color(0xFFD6C8E3)),
                    ),
                  ),
                  Text(
                    '$_progress%',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _errorMessage != null ? Colors.red : const Color(0xFF7A28CB), // Deep purple
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 40),
            
            if (isDone)
              Text(
                _errorMessage ?? 'تم استخراج المؤشرات الحيوية وفهم نتائج التحليل',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: _errorMessage != null ? Colors.red : const Color(0xFF65418F),
                ),
                textAlign: TextAlign.center,
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
                    'قراءة النتائج المعملية',
                    '( جارِ فهم وتحليل المعلومات الطبية )',
                    _progress > 60,
                    Icons.biotech_outlined,
                  ),
                  _buildStepRow(
                    'تجهيز النتائج',
                    _errorMessage != null ? 'حدث خطأ أثناء الاتصال بالخادم' : '( جارِ تجهيز التفسير والتوصيات )',
                    _progress >= 100,
                    Icons.analytics_outlined,
                    isError: _errorMessage != null,
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
                    onPressed: _errorMessage != null 
                        ? () => Navigator.pop(context)
                        : () {
                            Navigator.pushNamed(
                              context, 
                              AppRouter.scannerResults, 
                              arguments: _scanResults
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _errorMessage != null ? Colors.red : const Color(0xFF563B7E), // Deep purple
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _errorMessage != null ? 'عودة' : 'عرض النتائج',
                      style: const TextStyle(
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
