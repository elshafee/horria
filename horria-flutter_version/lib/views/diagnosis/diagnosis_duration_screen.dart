import 'package:flutter/material.dart';
import '../../core/routes/app_router.dart';
import 'diagnosis_layout.dart';

class DiagnosisDurationScreen extends StatefulWidget {
  const DiagnosisDurationScreen({super.key});

  @override
  State<DiagnosisDurationScreen> createState() => _DiagnosisDurationScreenState();
}

class _DiagnosisDurationScreenState extends State<DiagnosisDurationScreen> {
  String? _selectedDuration;

  final List<String> _durations = [
    'أقل من يوم',
    '1 - 3 أيام',
    'أسبوع أو أكثر',
  ];

  void _onNext() {
    if (_selectedDuration == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'يرجى اختيار المدة للمتابعة.',
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final List<String> categories = (ModalRoute.of(context)?.settings.arguments as List<String>?) ?? [];
    
    Navigator.pushNamed(
      context,
      AppRouter.diagnosisLoading,
      arguments: {
        'symptoms': categories,
        'duration': _selectedDuration,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get selected categories from previous screen
    final List<String> categories = (ModalRoute.of(context)?.settings.arguments as List<String>?) ?? [];
    
    // Create a natural sounding arabic sentence for the selected categories
    String categoriesText = categories.join(' و');
    if (categories.isEmpty) {
      categoriesText = 'هذه الأعراض';
    }

    return DiagnosisLayout(
      title: 'تشخيص الأمراض',
      robotMessage: 'د حورية بتسألك عشان تفهم حالتك أكتر',
      showBackButton: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40),
            Center(
              child: Text(
                'اخترت $categoriesText. منذ متى بدأت هذه الأعراض؟',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  color: Color(0xFF65418F),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 50),
            
            Row(
              children: _durations.map((duration) {
                final isSelected = _selectedDuration == duration;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedDuration = duration;
                        });
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 60,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFDE8ED) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFFF85A1) : Colors.grey.withOpacity(0.2),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          duration,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? const Color(0xFF65418F) : Colors.black87,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            
            const Spacer(),
            
            Align(
              alignment: Alignment.center,
              child: SizedBox(
                width: 300,
                height: 55,
                child: ElevatedButton(
                  onPressed: _onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF65418F),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'ابدأ التشخيص',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
