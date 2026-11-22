import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:speech_to_text/speech_to_text.dart';
import '../../core/routes/app_router.dart';
import '../../core/network/auth_store.dart';
import '../../core/network/api_config.dart';
import 'diagnosis_layout.dart';

class DiagnosisHomeScreen extends StatefulWidget {
  const DiagnosisHomeScreen({super.key});

  @override
  State<DiagnosisHomeScreen> createState() => _DiagnosisHomeScreenState();
}

class _DiagnosisHomeScreenState extends State<DiagnosisHomeScreen> {
  final Set<String> _selectedCategories = {};
  
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _customSymptom = "";

  final List<String> _mainCategories = [
    'حمى أو ارتفاع حرارة',
    'أعراض تنفسية',
    'أعراض القلب والدورة الدموية',
    'آلام الجسم',
    'مشاكل الجهاز الهضمي',
    'أعراض أخرى',
  ];

  final List<String> _otherCategories = [
    'صداع مستمر',
    'دوخة ودوار',
    'طفح جلدي',
    'تنميل الأطراف',
    'رؤية ضبابية',
    'صعوبة في التحدث',
    'إرهاق وضعف عام',
    'ألم أثناء التبول',
  ];

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _speakInitialMessage();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  Future<void> _speakInitialMessage() async {
    String userName = AuthStore().userName ?? "صديقي";
    String message = 'أهلا يا $userName ... سأساعدك في تقييم حالتك الصحية اليوم ... اختر ما يناسبك.';
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/diagnosis/speak'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": message}),
      );
    } catch (e) {
      print('Error speaking initial message: $e');
    }
  }

  void _toggleCategory(String category) {
    setState(() {
      if (_selectedCategories.contains(category)) {
        _selectedCategories.remove(category);
      } else {
        _selectedCategories.add(category);
      }
    });
  }

  Future<void> _triggerVoiceDictation() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "ar_EG",
          onResult: (result) {
            setState(() {
              _customSymptom = result.recognizedWords;
            });
            if (result.finalResult) {
              setState(() {
                _isListening = false;
                if (_customSymptom.isNotEmpty) {
                  _selectedCategories.add(_customSymptom);
                  _customSymptom = "";
                }
              });
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
      if (_customSymptom.isNotEmpty) {
        setState(() {
          _selectedCategories.add(_customSymptom);
          _customSymptom = "";
        });
      }
    }
  }

  void _onNext() {
    if (_selectedCategories.isEmpty) {
      String warningMsg = 'يرجى اختيار عرض واحد على الأقل للمتابعة.';
      
      // Speak the warning
      http.post(
        Uri.parse('${ApiConfig.baseUrl}/diagnosis/speak'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": warningMsg}),
      ).catchError((e) => print('Error speaking warning: $e'));

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warningMsg,
            textAlign: TextAlign.center,
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    
    Navigator.pushNamed(
      context,
      AppRouter.diagnosisDuration,
      arguments: _selectedCategories.toList(),
    );
  }

  Widget _buildCategoryGrid(List<String> categories) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.0,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = _selectedCategories.contains(category);
        
        return InkWell(
          onTap: () => _toggleCategory(category),
          borderRadius: BorderRadius.circular(16),
          child: Container(
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
              category,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? const Color(0xFF65418F) : Colors.black87,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String userName = AuthStore().userName ?? "صديقي";
    bool showOtherCategories = _selectedCategories.contains('أعراض أخرى');

    return DiagnosisLayout(
      title: 'تشخيص الأمراض',
      robotMessage: 'أهلا يا $userName ... سأساعدك في تقييم حالتك الصحية اليوم ... اختر ما يناسبك.',
      showBackButton: true,
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'اختر الأعراض التي تشعر بها اليوم، أو تحدث معي لأقوم بإضافتها كأعراض أخرى:',
                    style: TextStyle(
                      fontSize: 16,
                      color: Color(0xFF65418F),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isListening ? _triggerVoiceDictation : _triggerVoiceDictation,
                  icon: Icon(_isListening ? Icons.stop : Icons.mic, color: Colors.white),
                  label: Text(_isListening ? 'إيقاف الاستماع' : 'تحدث للأعراض', style: const TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isListening ? Colors.redAccent : const Color(0xFF65418F),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
            if (_customSymptom.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                child: Text(
                  'يتم تسجيل: $_customSymptom',
                  style: const TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            const SizedBox(height: 20),
            
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCategoryGrid(_mainCategories),
                    if (showOtherCategories) ...[
                      const SizedBox(height: 20),
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          'قائمة الأعراض الأخرى المتاحة:',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF65418F),
                          ),
                        ),
                      ),
                      _buildCategoryGrid(_otherCategories),
                    ],
                    const SizedBox(height: 20),
                    // Display dynamically spoken custom symptoms that aren't in predefined lists
                    if (_selectedCategories.isNotEmpty)
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _selectedCategories
                          .where((c) => !_mainCategories.contains(c) && !_otherCategories.contains(c))
                          .map((c) => Chip(
                            label: Text(c, style: const TextStyle(fontSize: 14)),
                            onDeleted: () => _toggleCategory(c),
                            backgroundColor: const Color(0xFFFDE8ED),
                            side: const BorderSide(color: Color(0xFFFF85A1)),
                          )).toList(),
                      ),
                  ],
                ),
              ),
            ),
            
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
                    'التالي',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}
