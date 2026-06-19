import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/measurement_type.dart';
import '../../lepu_service.dart';
import '../../core/constants/app_strings.dart';
import '../../data/measurement_store.dart';
import '../../core/network/vitals_service.dart';
import '../../presentation/global_widgets/sdui_primary_button.dart';

enum MeasurementPhase { instruction, measuring, success, failure }

class MeasurementPopupDialog extends StatefulWidget {
  final MeasurementType type;

  const MeasurementPopupDialog({super.key, required this.type});

  @override
  State<MeasurementPopupDialog> createState() => _MeasurementPopupDialogState();
}

class _MeasurementPopupDialogState extends State<MeasurementPopupDialog> with SingleTickerProviderStateMixin {
  MeasurementPhase _phase = MeasurementPhase.instruction;
  
  // Instruction Phase State
  late List<Map<String, String>> _steps;
  int _currentStep = 0;
  late PageController _pageController;

  // Measuring Phase State
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription? _lepuSubscription;
  Timer? _continuousTimer;
  Map<String, dynamic>? _lastData;
  String _status = AppStrings.measuringStatus;
  final List<double> _ecgPoints = [];

  bool _isUploading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _steps = widget.type.instructions;
    _pageController = PageController();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    LepuService.initSdk();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakCurrentInstruction(0);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _pulseController.dispose();
    _lepuSubscription?.cancel();
    _continuousTimer?.cancel();
    _stopHardware();
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
      debugPrint('Error speaking text: $e');
    }
  }

  Future<void> _speakCurrentInstruction(int index) async {
    if (index >= 0 && index < _steps.length) {
      String instructionText = _steps[index]['instruction'] ?? '';
      _speakText(instructionText);
    }
  }

  void _nextInstructionStep() {
    if (_currentStep < _steps.length - 1) {
      if (_pageController.hasClients) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    } else {
      _startMeasuringPhase();
    }
  }

  void _previousInstructionStep() {
    if (_currentStep > 0) {
      if (_pageController.hasClients) {
        _pageController.previousPage(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _startMeasuringPhase() {
    setState(() {
      _phase = MeasurementPhase.measuring;
    });
    _speakText('انتظر بهدوء، لا تتحدث أو تتحرك حتى ينتهي القياس.');
    _startMeasurementHardware();
  }

  void _startMeasurementHardware() async {
    try {
      switch (widget.type) {
        case MeasurementType.bloodPressure: await LepuService.startBp(); break;
        case MeasurementType.ecg: await LepuService.startEcg(); break;
        default: break;
      }
    } catch (e) {
      debugPrint("Error starting measurement: $e");
    }

    final expectedEvent = widget.type.expectedEvent;
    
    _lepuSubscription = LepuService.listenToUpdates().listen((event) {
      if (!mounted) return;
      if (event is! Map) return;

      final String type = event['type'];
      final dynamic data = event['data'];
      
      if (type == 'status') {
        setState(() => _status = data.toString());
      } else if (type == 'RtBpData' && widget.type == MeasurementType.bloodPressure) {
        setState(() => _status = "الضغط الحالي: $data");
      } else if (type == 'ecgWave' && widget.type == MeasurementType.ecg) {
        if (data is Map && data.containsKey('floats')) {
          final List<dynamic> points = data['floats'];
          for (var p in points) {
            _ecgPoints.add(p.toDouble());
          }
          if (_ecgPoints.length > 500) {
            _ecgPoints.removeRange(0, _ecgPoints.length - 500);
          }
        }
      }
      
      if (type == expectedEvent) {
        if (data is Map) {
          _lastData = Map<String, dynamic>.from(data);
        } else {
          _lastData = {'value': data};
        }
        _processMeasurementResult();
        return;
      }
      
      if (type == 'ecgResult' && widget.type == MeasurementType.ecg) {
        if (data is Map) {
          _lastData = Map<String, dynamic>.from(data);
        } else {
          _lastData = {'value': data};
        }
        _processMeasurementResult();
        return;
      }
      
      if (type == 'ecgMode' && data == 'STOPPED' && widget.type == MeasurementType.ecg) {
        _continuousTimer?.cancel();
        _continuousTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && _phase == MeasurementPhase.measuring) {
            _processMeasurementResult();
          }
        });
      }
    });

    if (widget.type == MeasurementType.ecg) {
      _continuousTimer = Timer(const Duration(seconds: 90), () {
        if (mounted && _phase == MeasurementPhase.measuring) _processMeasurementResult();
      });
    } else if (expectedEvent != 'bpResult') {
      _continuousTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && _phase == MeasurementPhase.measuring) _processMeasurementResult();
      });
    }
  }

  Future<void> _stopHardware() async {
    try {
      switch (widget.type) {
        case MeasurementType.bloodPressure: await LepuService.stopBp(); break;
        case MeasurementType.ecg: await LepuService.stopEcg(); break;
        default: break;
      }
    } catch (e) {
      debugPrint("Error stopping measurement: $e");
    }
  }

  void _processMeasurementResult() async {
    if (_phase != MeasurementPhase.measuring) return;
    
    _continuousTimer?.cancel();
    _lepuSubscription?.cancel();
    await _stopHardware();

    if (!mounted) return;

    if (_lastData == null) {
      if (widget.type == MeasurementType.ecg) {
        _lastData = {'hr': 0, 'result': 0, 'resultMess': 'تم القياس - لم يتم استلام النتيجة'};
      } else {
        _lastData = {'value': 0};
      }
    }

    bool isZero = false;
    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    if (widget.type == MeasurementType.bloodPressure) {
      final sys = parseDouble(_lastData!['sys']);
      final dia = parseDouble(_lastData!['dia']);
      if ((sys == null || sys == 0) && (dia == null || dia == 0)) isZero = true;
    } else if (widget.type == MeasurementType.ecg) {
      final hr = parseDouble(_lastData!['hr'] ?? _lastData!['pr'] ?? _lastData!['value']);
      if ((hr == null || hr == 0) && _ecgPoints.isEmpty) isZero = true;
    } else {
      final val = parseDouble(_lastData!['value'] ?? _lastData!['temp'] ?? _lastData!['spo2'] ?? _lastData!['hr'] ?? _lastData!['pr'] ?? _lastData!['glucose']);
      if (val == null || val == 0) isZero = true;
    }

    if (isZero) {
      setState(() {
        _phase = MeasurementPhase.failure;
        _errorMessage = 'النتيجة صفر، يرجى المحاولة مرة أخرى.';
      });
      _speakText('النتيجة صفر، يرجى إعادة المحاولة');
      return;
    }

    setState(() {
      _isUploading = true;
    });
    _speakText('جاري حفظ النتائج');

    if (widget.type == MeasurementType.ecg && _ecgPoints.isNotEmpty) {
      _lastData!['ecg_wave'] = _ecgPoints;
      MeasurementStore().updateEcgWaveData(
        _ecgPoints,
        resultMessage: _lastData?['resultMess']?.toString(),
        diagnosisResult: _lastData?['result'] is int ? _lastData!['result'] : null,
      );
    }

    MeasurementStore().updateMeasurement(widget.type, _lastData);
    
    try {
      await VitalsService().postVitals(widget.type, _lastData ?? {});
    } catch (e) {
      debugPrint("Backend post failed: $e");
    }

    if (!mounted) return;

    setState(() {
      _isUploading = false;
      _phase = MeasurementPhase.success;
    });
    _speakText('تم اكتمال القياس بنجاح');

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context, true); // Return true to indicate success
      }
    });
  }

  Widget _buildInstructionPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 300,
          child: PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            onPageChanged: (index) {
              setState(() {
                _currentStep = index;
              });
              _speakCurrentInstruction(index);
            },
            itemCount: _steps.length,
            itemBuilder: (context, index) {
              final step = _steps[index];
              return Row(
                children: [
                  if (step['image'] != null)
                    Expanded(
                      flex: 1,
                      child: Container(
                        margin: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.white,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Image.asset(
                          step['image']!,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    )
                  else
                    Expanded(
                      flex: 1,
                      child: Center(
                        child: Image.asset(
                          'assets/images/measurements/icons/${widget.type.name}.png',
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.image_not_supported,
                            size: 64,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  Expanded(
                    flex: 1,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          step['step']!,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFFFF85A1),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          step['instruction']!,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontSize: 20,
                            color: Color(0xFF2D2340),
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
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 130,
                  child: SduiPrimaryButton(
                    text: _currentStep == _steps.length - 1 
                        ? 'ابدأ القياس' 
                        : 'التالي',
                    onPressed: _nextInstructionStep,
                    backgroundColor: const Color(0xFF65418F),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 130,
                  height: 55,
                  child: OutlinedButton(
                    onPressed: _currentStep == 0 ? null : _previousInstructionStep,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF65418F),
                      side: BorderSide(
                        color: _currentStep == 0 ? Colors.grey : const Color(0xFF65418F),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text('السابق', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_steps.length, (index) {
                bool isSelected = index == _currentStep;
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
      ],
    );
  }

  Widget _buildMeasuringPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 150,
          width: 150,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF85A1)),
                strokeWidth: 8,
              ),
              ScaleTransition(
                scale: _pulseAnimation,
                child: const Icon(
                  Icons.favorite,
                  color: Color(0xFF65418F),
                  size: 60,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Text(
          _isUploading ? 'جاري حفظ النتيجة...' : _status,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF65418F),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessPhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.check_circle, color: Colors.green, size: 100),
        const SizedBox(height: 24),
        Text(
          'تمت القراءة بنجاح لـ ${widget.type.title}',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF65418F),
          ),
        ),
      ],
    );
  }

  Widget _buildFailurePhase() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 80),
        const SizedBox(height: 24),
        Text(
          _errorMessage ?? 'حدث خطأ',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF65418F),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: 200,
          child: SduiPrimaryButton(
            text: 'المحاولة مرة أخرى',
            onPressed: () {
              setState(() {
                _phase = MeasurementPhase.instruction;
                _currentStep = 0;
              });
              // Use addPostFrameCallback to ensure PageView is built and attached before jumping
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_pageController.hasClients) {
                  _pageController.jumpToPage(0);
                }
              });
              _speakCurrentInstruction(0);
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    switch (_phase) {
      case MeasurementPhase.instruction: content = _buildInstructionPhase(); break;
      case MeasurementPhase.measuring: content = _buildMeasuringPhase(); break;
      case MeasurementPhase.success: content = _buildSuccessPhase(); break;
      case MeasurementPhase.failure: content = _buildFailurePhase(); break;
    }

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F7FA),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.type.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF65418F),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    if (_phase == MeasurementPhase.measuring) {
                      _stopHardware();
                    }
                    Navigator.pop(context, false);
                  },
                ),
              ],
            ),
            const Divider(height: 32),
            Directionality(
              textDirection: TextDirection.rtl,
              child: content,
            ),
          ],
        ),
      ),
    );
  }
}
