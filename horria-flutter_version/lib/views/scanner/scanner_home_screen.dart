import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';

class ScannerHomeScreen extends StatelessWidget {
  const ScannerHomeScreen({super.key});

  Widget _buildTypePill(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDE8ED), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF65418F),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: const Color(0xFFFF85A1), size: 20),
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
                  children: [
                    // Header Area
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'الماسح الطبي',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            if (Navigator.canPop(context)) {
                              Navigator.pop(context);
                            }
                          },
                          child: const Row(
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
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        'تأكد من وضع المستند الطبي بحيث تكون الكتابة موجهة للأسفل ومحاذاة للحافة اليمنى للماسح الضوئي، ثم أغلق الغطاء برفق لبدء القراءة.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),
                    
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Interactive Scanner Area
                            GestureDetector(
                              onTap: () {
                                // Simulate placing document and starting scan
                                Navigator.pushNamed(context, AppRouter.scannerProgress);
                              },
                              child: Container(
                                width: 300,
                                height: 200,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1EEF5),
                                  borderRadius: BorderRadius.circular(24),
                                  border: Border.all(color: const Color(0xFF65418F).withOpacity(0.2), width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF65418F).withOpacity(0.05),
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Icon(
                                      Icons.document_scanner_outlined,
                                      size: 100,
                                      color: const Color(0xFF65418F).withOpacity(0.5),
                                    ),
                                    // Animated scan line effect could go here
                                  ],
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 40),
                            const Text(
                              'اضغط لبدء المسح',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF65418F),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 20),
                              child: Text(
                                'الماسح يدعم التحاليل المعملية، الروشتات، والأشعة. يرجى التأكد من أن المستند واضح وخالي من الطيات العميقة لضمان دقة الاستخراج.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 15,
                                  height: 1.5,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: [
                                _buildTypePill('روشتات', Icons.receipt_long),
                                _buildTypePill('تحاليل', Icons.science_outlined),
                                _buildTypePill('تقارير', Icons.assignment_outlined),
                              ],
                            ),
                          ],
                        ),
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
