import 'package:flutter/material.dart';
import '../../presentation/global_widgets/sdui_sidebar.dart';

class MeasurementLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final int sidebarSelectedIndex;

  const MeasurementLayout({
    super.key,
    required this.title,
    required this.child,
    this.sidebarSelectedIndex = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F7FA),
      body: Stack(
        clipBehavior: Clip.none,
        children: [
          // Background Waves extending under sidebar
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

          Row(
            children: [
              // Main Content
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Back Button
                        InkWell(
                          onTap: () => Navigator.pop(context),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'رجوع',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFF65418F),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(
                                Icons.arrow_forward,
                                color: Color(0xFF65418F),
                                size: 20,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF65418F),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],

                        // The dynamic content for the screen
                        Expanded(child: child),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
