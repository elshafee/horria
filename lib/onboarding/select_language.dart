import 'package:flutter/material.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState
    extends State<LanguageSelectionScreen> {

  String selectedLanguage = 'ar';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [

          /// Background
          Positioned.fill(
            child: Image.asset(
              'assets/images/background.png',
              fit: BoxFit.cover,
            ),
          ),

          /// Content
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [

                  /// Logo
                  Image.asset(
                    'assets/images/horria_ar.png',
                    height: 70,
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'الرجاء اختيار اللغة المفضلة للمتابعة',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF65418F),
                    ),
                  ),

                  const SizedBox(height: 50),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      /// English Card
                      LanguageCard(
                        title: 'English',
                        selected: selectedLanguage == 'en',
                        onTap: () {
                          setState(() {
                            selectedLanguage = 'en';
                          });
                        },
                      ),

                      const SizedBox(width: 30),

                      /// Arabic Card
                      LanguageCard(
                        title: 'العربية',
                        selected: selectedLanguage == 'ar',
                        onTap: () {
                          setState(() {
                            selectedLanguage = 'ar';
                          });
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 45),

                  SizedBox(
                    width: 360,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: () {

                        if (selectedLanguage == 'ar') {
                          print('Arabic Selected');
                        //   main_auth
                          Navigator.of(context).pushNamed('/main_auth');
                        } else {
                          print('English Selected');
                          Navigator.of(context).pushNamed('/main_auth');

                        }

                        // Navigate Here
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF684293),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'متابعة',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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

class LanguageCard extends StatelessWidget {
  final String title;
  final bool selected;
  final VoidCallback onTap;

  const LanguageCard({
    super.key,
    required this.title,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {

    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        width: 360,
        height: 180,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(
            selected ? 0.75 : 0.95,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: selected
                ? const Color(0xFFFF69A8)
                : const Color(0xFFE5E5E5),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [

            if (selected)
              const Positioned(
                top: 12,
                right: 12,
                child: CircleAvatar(
                  radius: 14,
                  backgroundColor: Color(0xFFFF69A8),
                  child: Icon(
                    Icons.check,
                    size: 18,
                    color: Colors.white,
                  ),
                ),
              ),

            Center(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF34264F),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}