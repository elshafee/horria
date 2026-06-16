import 'package:flutter/material.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background Image
          Positioned.fill(
            child: Image.asset(
              'assets/images/splash.png',
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
                          Image.asset(
                            'assets/images/horria_ar.png',
                            height: 70,
                          ),

                          const SizedBox(height: 24),

                          const Text(
                            'أهلاً بك مع حورية ... مساعدك الطبي الذكي',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF55307D),
                            ),
                          ),

                          const SizedBox(height: 30),

                          SizedBox(
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