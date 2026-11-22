import 'package:flutter/material.dart';
import '../core/animations/animations.dart';
import '../core/network/tts_service.dart';

class AuthMainScreen extends StatefulWidget {
  const AuthMainScreen({super.key});

  @override
  State<AuthMainScreen> createState() => _AuthMainScreenState();
}

class _AuthMainScreenState extends State<AuthMainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TtsService.speak('اختر إحدى الخيارات للمتابعة، مستخدم جديد أو التعرف على الوجه');
    });
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4294);

    return Scaffold(
      body: Stack(
        children: [
          // Background with transparency
          Positioned.fill(
            child: Image.asset(
              'assets/images/common/background.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: SizedBox(
              height: MediaQuery.of(context).size.height,
              width: MediaQuery.of(context).size.width,
              child: const Opacity(
                opacity: 0.7,
                child: ColoredBox(color: Colors.white),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 100),

                  // Logo
                  FadeInSlide(
                    duration: AppAnimations.normal,
                    beginOffset: const Offset(0, -30),
                    child: Image.asset('assets/images/onboarding/horria_ar.png', height: 70),
                  ),

                  const SizedBox(height: 5),

                  const FadeInSlide(
                    delay: 0.1,
                    beginOffset: Offset(-50, 0),
                    child: Text(
                      'أهلاً بك مع حورية',
                      style: TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ),

                  const SizedBox(height: 5),

                  const FadeInSlide(
                    delay: 0.2,
                    beginOffset: Offset(50, 0),
                    child: Text(
                      'مساعدك الطبي الذكي لرعاية صحية أفضل',
                      style: TextStyle(fontSize: 20, color: Color(0xff6B5A7A)),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  const SizedBox(height: 60),

                  Row(
                    children: [
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 160,
                            right: 10,
                          ),
                          child: FadeInSlide(
                            delay: 0.3,
                            beginOffset: const Offset(-80, 0),
                            child: _OptionCard(
                              title: 'مستخدم جديد',
                              subtitle: 'إنشاء حساب جديد',
                              icon: Icons.person_add_alt_1,
                              filled: true,
                              onTap: () {
                                Navigator.of(context).pushNamed('/register');
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(
                            left: 10,
                            right: 160,
                          ),
                          child: FadeInSlide(
                            delay: 0.4,
                            beginOffset: const Offset(80, 0),
                            child: _OptionCard(
                              title: 'التعرف على الوجه',
                              subtitle: 'للمستخدمين المسجلين سابقاً',
                              icon: Icons.face,
                              filled: false,
                              onTap: () {
                                Navigator.of(context).pushNamed('/login');
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  const FadeInSlide(
                    delay: 0.5,
                    beginOffset: Offset(0, 30),
                    child: Text(
                      'اختر إحدى الخيارات للمتابعة',
                      style: TextStyle(fontSize: 22, color: Color(0xff6B5A7A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _OptionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.filled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF6A4294);

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.27,
        decoration: BoxDecoration(
          color: filled ? primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: filled ? null : Border.all(color: primaryColor, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 38, color: filled ? Colors.white : primaryColor),
              const SizedBox(height: 18),
              Text(
                title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: filled ? Colors.white : const Color(0xFF2D2340),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 18,
                  color: filled ? Colors.white70 : Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
