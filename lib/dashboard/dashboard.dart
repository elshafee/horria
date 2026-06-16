import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();

  static Widget _sideIcon(
      String path, {
        bool selected = false,
      }) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: selected
            ? const Color(0xffFF6EA8)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: EdgeInsetsGeometry.all(5),
        child: Image.asset(
          path,
        ),
      ),
    );
  }
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
      
            Positioned.fill(
              child: Image.asset(
                'assets/images/home_page_background.png',
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
            const Positioned(
              top: 60,
              right: 220,
              child: Text(
                '15 مايو 2026 | تاريخ اليوم',
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.black54,
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
                child: const Text(
                  'أهلاً يا إسراء ... جاهزة لمساعدتك في متابعة صحتك',
                  style: TextStyle(
                    fontSize: 26,
                    color: Color(0xff684293),
                    fontWeight: FontWeight.w600,
                  ),
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
                image: 'assets/images/clinic.png',
                title: 'العيادات',
              ),
            ),
      
            Positioned(
              left: 410,
              top: 470,
              child: _ServiceCard(
                image: 'assets/images/diagnoses.png',
                title: 'تشخيص الأمراض',
              ),
            ),
      
            Positioned(
              left: 790,
              top: 470,
              child: _ServiceCard(
                image: 'assets/images/vital_sign.png',
                title: 'قياس الإشارات الحيوية',
              ),
            ),
      
            /// Right Sidebar
            Positioned(
              top: 0,
              right: 0,
              bottom: 0,
              child: Container(
                width: 105,
                decoration: const BoxDecoration(
                  color: Color(0xFF563B7E),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(35),
                    bottomLeft: Radius.circular(35),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 30),
      
                    // HomeScreen._sideIcon(""),
      
                    Image.asset("assets/images/robot_icon.png"),
      
      
                    const SizedBox(height: 90),
      
                    HomeScreen._sideIcon(
                      "assets/images/home_icon.png",
                      selected: true,
                    ),
      
                    const SizedBox(height: 60),
                    HomeScreen._sideIcon(
                      "assets/images/diagnoses_icon.png",
                      selected: false,
                    ),
      
                    // HomeScreen._sideIcon(Icons.monitor_heart_outlined),
      
                    // const SizedBox(height: 60),
                    const SizedBox(height: 60),
                    HomeScreen._sideIcon(
                      "assets/images/history_icon.png",
                      selected: false,
                    ),
      
                    // HomeScreen._sideIcon(Icons.medical_services_outlined),
      
                    const Spacer(),
                    const SizedBox(height: 60),
                    HomeScreen._sideIcon(
                      "assets/images/logout_icon.png",
                      selected: false,
                    ),
      
                    // HomeScreen._sideIcon(Icons.logout),
      
                    const SizedBox(height: 40),
                  ],
                ),
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

  const _ServiceCard({
    required this.image,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
                width: 150,
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
    );
  }
}