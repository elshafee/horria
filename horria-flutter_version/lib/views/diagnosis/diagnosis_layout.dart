import 'package:flutter/material.dart';

class DiagnosisLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final String? robotMessage;
  final bool showBackButton;

  const DiagnosisLayout({
    super.key,
    required this.title,
    required this.child,
    this.robotMessage,
    this.showBackButton = true,
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
              // Left Column with Robot
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.40,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: -20,
                      bottom: 0,
                      child: Image.asset(
                        'assets/images/common/robot.png',
                        height: MediaQuery.of(context).size.height * 0.7,
                        fit: BoxFit.contain,
                      ),
                    ),
                    if (robotMessage != null)
                      Positioned(
                        top: MediaQuery.of(context).size.height * 0.3,
                        left: 140, // Adjust based on robot position
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.35,
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDE8ED), // Light pink bubble
                            borderRadius: BorderRadius.circular(24).copyWith(
                              bottomLeft: Radius.zero,
                            ),
                          ),
                          child: Text(
                            robotMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF65418F),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 24.0, bottom: 24.0, left: 24.0, right: 30),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Back Button
                        if (showBackButton)
                          InkWell(
                            onTap: () {
                              if (Navigator.canPop(context)) {
                                Navigator.pop(context);
                              }
                            },
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
                          )
                        else
                          const SizedBox(height: 24), // Maintain spacing
                          
                        const SizedBox(height: 20),

                        if (title.isNotEmpty) ...[
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 32,
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
