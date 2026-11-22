import 'package:flutter/material.dart';
import '../core/animations/animations.dart';
import '../core/network/tts_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.speak('أهلاً بك مع حورية، مساعدك الطبي الذكي');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
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
                            beginOffset: const Offset(-50, 0), // Slide from left
                            child: Image.asset(
                              'assets/images/onboarding/horria_ar.png',
                              height: 70,
                            ),
                          ),

                          const SizedBox(height: 24),

                          const FadeInSlide(
                            delay: 0.2,
                            beginOffset: Offset(50, 0), // Slide from right
                            child: Text(
                              'أهلاً بك مع حورية ... مساعدك الطبي الذكي',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 34,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF55307D),
                              ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          FadeInSlide(
                            delay: 0.4,
                            beginOffset: const Offset(0, 50), // Slide from bottom
                            child: SizedBox(
                              width: 260,
                              height: 55,
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.of(context).pushNamed('/language');
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
                                  'ابدأ الآن',
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
