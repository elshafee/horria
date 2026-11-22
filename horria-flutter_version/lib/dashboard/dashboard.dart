import 'package:flutter/material.dart';
import 'package:horria_t/core/routes/app_router.dart';
import '../presentation/global_widgets/sdui_sidebar.dart';
import '../core/network/auth_store.dart';
import '../core/animations/animations.dart';
import '../core/network/tts_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final name = AuthStore().userName ?? '';
      TtsService.speak("أهلاً بك يا $name، أنا الدكتورة حورية وموجودة لمساعدتك.");
    });
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
    final timeStr = '${now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour)}:${now.minute.toString().padLeft(2, '0')} ${now.hour >= 12 ? 'م' : 'ص'}';

    return Scaffold(
      backgroundColor: Colors.transparent, // Allow shell background to show if any
      body: SafeArea(
        child: Stack(
          clipBehavior: Clip.none, // Allow background to bleed under sidebar area
          children: [
            // Background covers the whole screen (under the sidebar too)
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: -105, // Extend background under the sidebar
              child: Image.asset(
                'assets/images/dashboard/home_page_background.png',
                fit: BoxFit.cover,
              ),
            ),
            /// Top Left Language
            Positioned(
              top: 60,
              left: 80,
              child: FadeInSlide(
                duration: AppAnimations.normal,
                beginOffset: const Offset(-30, 0),
                child: Row(
                  children: const [
                    Text(
                      'English',
                      style: TextStyle(
                        fontSize: 22,
                        color: Colors.black54,
                      ),
                    ),
                    SizedBox(width: 20),
                    Text(
                      '|',
                      style: TextStyle(fontSize: 22),
                    ),
                    SizedBox(width: 20),
                    Text(
                      'العربية',
                      style: TextStyle(
                        fontSize: 22,
                        color: Color(0xffF45A9C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      
            /// Date
            Positioned(
              top: 60,
              right: 50,
              child:  FadeInSlide(
                duration: AppAnimations.normal,
                beginOffset: const Offset(30, 0),
                child: Text(
                  'اليوم: $dateStr | $timeStr',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),
            ),
      
            /// Welcome Bubble
            Positioned(
              top: 150,
              left: 240,
              child: FadeInSlide(
                delay: 0.1,
                beginOffset: const Offset(0, -30),
                child: Container(
                  width: 650,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xffF7DDE8),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Text(
                    AuthStore().greeting ?? 'أهلاً بك ... جاهزة لمساعدتك في متابعة صحتك',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Color(0xff684293),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            /// Subtitle
            Positioned(
              top: 330,
              left: 330,
              child: FadeInSlide(
                delay: 0.2,
                beginOffset: const Offset(0, 30),
                child: const Text(
                  'كل ما عليك فعله هو اختيار إحدى الخدمات التالية للوصول إلى الرعاية التي تحتاجها',
                  style: TextStyle(
                    fontSize: 24,
                    color: Color(0xff7A6394),
                  ),
                ),
              ),
            ),
      
            /// Message circle
            Positioned(
              left: 195,
              top: 205,
              child: FadeInSlide(
                delay: 0.1,
                beginOffset: const Offset(-50, 0),
                child: Container(
                  width: 150,
                  height: 150,
                  decoration:  const BoxDecoration(
                    shape: BoxShape.circle,
                    // color: Colors.tra,
                    image: DecorationImage(image: AssetImage("assets/images/dashboard/speak.gif"))
                  ),
                  alignment: Alignment.center,
                  child:
                  const Text(
                    '',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
      

      
            /// Cards
            Positioned(
              left: 30,
              top: 470,
              child: FadeInSlide(
                delay: 0.3,
                beginOffset: const Offset(-50, 50),
                child: const _ServiceCard(
                  image: 'assets/images/dashboard/clinics.gif',
                  title: 'العيادات',
                  route: AppRouter.clinicsList,
                ),
              ),
            ),
      
            Positioned(
              left: 435,
              top: 470,
              child: FadeInSlide(
                delay: 0.4,
                beginOffset: const Offset(0, 50),
                child: const _ServiceCard(
                  image: 'assets/images/dashboard/diagnoses.gif',
                  title: 'تشخيص الأمراض',
                  route: AppRouter.aiInterview,
                ),
              ),
            ),
      
            Positioned(
              right: 30,
              top: 470,
              child: FadeInSlide(
                delay: 0.5,
                beginOffset: const Offset(50, 50),
                child: const _ServiceCard(
                  image: 'assets/images/dashboard/vital.gif',
                  title: 'قياس الإشارات الحيوية',
                  route: AppRouter.vitalSignsHome,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatefulWidget {
  final String image;
  final String title;
  final String route;

  const _ServiceCard({
    required this.image,
    required this.title,
    required this.route,
  });

  @override
  State<_ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<_ServiceCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: (){
        Navigator.of(context).pushNamed(widget.route);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 360,
          height: 220,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(_isPressed ? 0.05 : 0.1),
                blurRadius: _isPressed ? 4 : 8,
                offset: Offset(0, _isPressed ? 2 : 4),
              )
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Image.asset(
                      widget.image,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Container(
                  height: 65,
                  decoration: const BoxDecoration(
                    color: Color(0xFF563B7E),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(22),
                      bottomRight: Radius.circular(22),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
