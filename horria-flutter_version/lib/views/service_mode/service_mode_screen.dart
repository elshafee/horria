import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../core/animations/animations.dart';

class ServiceModeScreen extends StatefulWidget {
  const ServiceModeScreen({super.key});

  @override
  State<ServiceModeScreen> createState() => _ServiceModeScreenState();
}

class _ServiceModeScreenState extends State<ServiceModeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image (same identity as splash)
          Positioned.fill(
            child: Image.asset(
              'assets/images/onboarding/splash.png',
              fit: BoxFit.cover,
            ),
          ),

          // Content Layer
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          FadeInSlide(
                            duration: AppAnimations.slow,
                            beginOffset: const Offset(-50, 0),
                            child: AnimatedBuilder(
                              animation: _spinController,
                              builder: (_, child) {
                                return Transform.rotate(
                                  angle: _spinController.value * 2 * math.pi,
                                  child: child,
                                );
                              },
                              child: const Icon(
                                Icons.settings_suggest,
                                size: 100,
                                color: Color(0xFF6D3A98),
                              ),
                            ),
                          ),

                          const SizedBox(height: 24),

                          const FadeInSlide(
                            delay: 0.2,
                            beginOffset: Offset(50, 0),
                            child: Text(
                              'النظام في وضع الخدمة',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF55307D),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          const FadeInSlide(
                            delay: 0.3,
                            beginOffset: Offset(50, 0),
                            child: Text(
                              'يرجى الانتظار، جاري إجراء الصيانة...',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w500,
                                color: Colors.black54,
                              ),
                            ),
                          ),

                          const SizedBox(height: 40),

                          FadeInSlide(
                            delay: 0.5,
                            beginOffset: const Offset(0, 50),
                            child: SizedBox(
                              width: 260,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6D3A98),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                                child: const Text(
                                  'العودة',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Empty space because robot already exists in image
                    const Expanded(
                      flex: 4,
                      child: SizedBox(),
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
