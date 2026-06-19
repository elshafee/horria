import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/measurement_type.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../core/theme/robot_theme.dart';
import '../../presentation/global_widgets/sdui_primary_button.dart';
import '../../lepu_service.dart';
import 'measurement_layout.dart';

class MeasurementInstructionScreen extends StatefulWidget {
  final MeasurementType type;
  final List<MeasurementType>? remainingTypes;

  const MeasurementInstructionScreen({
    super.key,
    required this.type,
    this.remainingTypes,
  });

  @override
  State<MeasurementInstructionScreen> createState() => _MeasurementInstructionScreenState();
}

class _MeasurementInstructionScreenState extends State<MeasurementInstructionScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  
  late List<Map<String, String>> _steps;
  late bool _isSinglePageMode;

  @override
  void initState() {
    super.initState();
    _steps = widget.type.instructions;
    _isSinglePageMode = widget.type == MeasurementType.oxygen || 
                        widget.type == MeasurementType.heartRate || 
                        widget.type == MeasurementType.glucose;
    
    // Auto-connect to the Lepu kit as soon as instructions are opened
    LepuService.initSdk();
    
    // Speak instructions
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_isSinglePageMode) {
        String allInstructions = _steps.map((s) => s['instruction']).join('. ');
        _speakText(allInstructions);
      } else {
        _speakCurrentInstruction(0);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _speakText(String text) async {
    try {
      await http.post(
        Uri.parse('http://192.168.1.9:8000/diagnosis/speak'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );
    } catch (e) {
      print('Error speaking text: $e');
    }
  }

  Future<void> _speakCurrentInstruction(int index) async {
    if (index >= 0 && index < _steps.length) {
      String instructionText = _steps[index]['instruction'] ?? '';
      _speakText(instructionText);
    }
  }

  void _startMeasurement() {
    Navigator.pushReplacementNamed(
      context,
      AppRouter.measurementMeasuring,
      arguments: {
        'type': widget.type,
        'remainingTypes': widget.remainingTypes,
      },
    );
  }

  void _nextPage() {
    if (_currentPage < _steps.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _startMeasurement();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildSinglePageLayout() {
    return Row(
      children: [
        // Left Image
        Expanded(
          flex: 4,
          child: Container(
            margin: const EdgeInsets.only(right: 40),
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/measurements/icons/${widget.type.name}.png', // Dynamic specific device image
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_not_supported,
                size: 100,
                color: Colors.grey,
              ),
            ),
          ),
        ),

        // Right Instructions List
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ..._steps.map((step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8ED).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        step['instruction']!,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Color(0xFF65418F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF85A1),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          step['step']!,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 30),
              // Start Button
              Align(
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 250,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _startMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF65418F),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'ابدأ القياس',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MeasurementLayout(
      title: widget.type.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          const Text(
            AppStrings.measurementInstructionSubtitle,
            style: TextStyle(
              fontSize: 18,
              color: Color(0xFF65418F),
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: _isSinglePageMode 
                ? _buildSinglePageLayout()
                : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _speakCurrentInstruction(index);
              },
              physics: const NeverScrollableScrollPhysics(), // Disable swipe to force button usage
              itemCount: _steps.length,
              itemBuilder: (context, index) {
                final step = _steps[index];
                return Row(
                  children: [
                    // Left Image
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(right: 40),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          step['image']!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.image_not_supported,
                            size: 100,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),

                    // Right Instructions
                    Expanded(
                      flex: 1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            step['step']!,
                            style: const TextStyle(
                              fontSize: 22,
                              color: Color(0xFFFF85A1),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            step['instruction']!,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 26,
                              color: Color(0xFF2D2340),
                              height: 1.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bottom Controls (Dots and Buttons) - Only for Multi-Page Mode
          if (!_isSinglePageMode)
            Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Buttons
                  Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: SduiPrimaryButton(
                          text: _currentPage == _steps.length - 1 
                              ? AppStrings.startMeasurementBtn 
                              : AppStrings.nextBtn,
                          onPressed: _nextPage,
                          backgroundColor: const Color(0xFF65418F),
                        ),
                      ),
                      const SizedBox(width: 16),
                      SizedBox(
                        width: 140,
                        height: 55,
                        child: OutlinedButton(
                          onPressed: _currentPage == 0 ? null : _previousPage,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFF65418F),
                            side: BorderSide(
                              color: _currentPage == 0 ? Colors.grey : const Color(0xFF65418F),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            AppStrings.previousBtn,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Dots
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(_steps.length, (index) {
                      bool isSelected = index == _currentPage;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFF85A1) : const Color(0xFFFF85A1).withOpacity(0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
