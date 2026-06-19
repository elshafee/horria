import 'package:flutter/material.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/robot_theme.dart';

/// A globally reusable Sidebar widget for the application.
class SduiSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<String>? onNavRequest;

  const SduiSidebar({
    super.key,
    this.selectedIndex = -1,
    this.onNavRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      width: 105,
      decoration: const BoxDecoration(
        color: RobotTheme.primaryPurple,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(35),
          bottomLeft: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset(
              'assets/images/common/robot_icon.png',
              width: 45,
              height: 45,
            ),
          ),

          const SizedBox(height: 60),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  InkWell(
                    onTap: () {
                      if (onNavRequest != null) {
                        onNavRequest!(AppRouter.dashboard);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, AppRouter.dashboard, (route) => false);
                      }
                    },
                    child: SideMenuItem(
                      icon: Icons.home_outlined,
                      title: 'الرئيسية',
                      isSelected: selectedIndex == 0,
                    ),
                  ),

                  const SizedBox(height: 40),

                  InkWell(
                    onTap: () {
                      if (onNavRequest != null) {
                        onNavRequest!(AppRouter.scannerHome);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, AppRouter.scannerHome, (route) => false);
                      }
                    },
                    child: SideMenuItem(
                      icon: Icons.crop_free,
                      title: 'الماسح',
                      isSelected: selectedIndex == 1,
                    ),
                  ),

                  const SizedBox(height: 40),

                  InkWell(
                    onTap: () {
                      if (onNavRequest != null) {
                        onNavRequest!(AppRouter.history);
                      } else {
                        Navigator.pushNamedAndRemoveUntil(context, AppRouter.history, (route) => false);
                      }
                    },
                    child: SideMenuItem(
                      icon: Icons.assignment_add,
                      title: 'السجل',
                      isSelected: selectedIndex == 2,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          Container(
            width: 60,
            height: 1,
            color: Colors.white24,
          ),

          const SizedBox(height: 20),

          InkWell(
            onTap: () {
              Navigator.pushNamedAndRemoveUntil(context, AppRouter.splash, (route) => false);
            },
            child: const SideMenuItem(
              icon: Icons.logout,
              title: 'خروج',
              isSelected: false,
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class SideMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final bool isSelected;

  const SideMenuItem({
    super.key,
    required this.icon,
    required this.title,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 85,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFF85A1) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 34,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
