import 'package:flutter/material.dart';
import 'package:horria_t/core/routes/app_router.dart';
import '../presentation/global_widgets/sdui_sidebar.dart';
import '../core/network/auth_store.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
      
            /// Date
            Positioned(
              top: 60,
              right: 220,
              child:  Text(
                'اليوم: $dateStr | $timeStr',
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
      
            /// Welcome Bubble
            Positioned(
              top: 150,
              left: 240,
              child: Container(
                width: 650,
                height: 85,
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
      
            /// Message circle
            Positioned(
              left: 195,
              top: 205,
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xffDB6AA0),
                ),
                alignment: Alignment.center,
                child: const Text(
                  '...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
      
            /// Subtitle
            const Positioned(
              top: 330,
              left: 330,
              child: Text(
                'كل ما عليك فعله هو اختيار إحدى الخدمات التالية للوصول إلى الرعاية التي تحتاجها',
                style: TextStyle(
                  fontSize: 24,
                  color: Color(0xff7A6394),
                ),
              ),
            ),
      
            /// Cards
            Positioned(
              left: 30,
              top: 470,
              child: _ServiceCard(
                image: 'assets/images/common/clinic.png',
                title: 'العيادات',
                route: AppRouter.clinicsList,
              ),
            ),
      
            Positioned(
              left: 410,
              top: 470,
              child: _ServiceCard(
                image: 'assets/images/common/diagnoses.png',
                title: 'تشخيص الأمراض',
                route: AppRouter.aiInterview,
              ),
            ),
      
            Positioned(
              left: 790,
              top: 470,
              child: _ServiceCard(
                image: 'assets/images/common/vital_sign.png',
                title: 'قياس الإشارات الحيوية',
                route: AppRouter.vitalSignsHome,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String image;
  final String title;
  final String route;

  const _ServiceCard({
    required this.image,
    required this.title,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: (){
        Navigator.of(context).pushNamed(route);
      },
      child: Container(
        width: 360,
        height: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  image,
                  // width: 300,
                  // height: 180,
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
                title,
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
    );
  }
}