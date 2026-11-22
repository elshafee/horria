import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../models/measurement_type.dart';
import '../../lepu_service.dart';
import '../../ecg_painter.dart';
import '../../core/constants/app_strings.dart';
import '../../core/routes/app_router.dart';
import '../../data/measurement_store.dart';
import '../../core/network/vitals_service.dart';
import '../../core/network/api_config.dart';
import 'measurement_layout.dart';

class MeasurementMeasuringScreen extends StatefulWidget {
  final MeasurementType type;
  final List<MeasurementType>? remainingTypes;

  const MeasurementMeasuringScreen({
    super.key,
    required this.type,
    this.remainingTypes,
  });

  @override
  State<MeasurementMeasuringScreen> createState() => _MeasurementMeasuringScreenState();
}

class _MeasurementMeasuringScreenState extends State<MeasurementMeasuringScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  
  StreamSubscription? _lepuSubscription;
  Timer? _continuousTimer;
  Map<String, dynamic>? _lastData;
  String _status = AppStrings.measuringStatus;
  final List<double> _ecgPoints = [];

  bool _isFinished = false;
  bool _isUploading = false;
  String? _finalInstruction;
  String? _finalStatus;

  Future<void> _speakText(String text) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/diagnosis/speak'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );
    } catch (e) {
      debugPrint('Error speaking text: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Animation setup
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _startMeasurement();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _speakText('انتظر بهدوء، لا تتحدث أو تتحرك حتى ينتهي القياس.');
    });
  }

  void _startMeasurement() async {
    // 1. Send hardware command
    try {
      switch (widget.type) {
        case MeasurementType.bloodPressure:
          await LepuService.startBp();
          break;
        case MeasurementType.ecg:
          await LepuService.startEcg();
          break;
        case MeasurementType.glucose:
        case MeasurementType.oxygen:
        case MeasurementType.heartRate:
        case MeasurementType.temperature:
          // These sensors broadcast automatically without a start command on PC300
          break;
      }
    } catch (e) {
      debugPrint("Error starting measurement: $e");
    }

    // 2. Listen to updates
    final expectedEvent = widget.type.expectedEvent;
    debugPrint("[MEASURE] Listening for expectedEvent='$expectedEvent' (type=${widget.type})");
    
    _lepuSubscription = LepuService.listenToUpdates().listen((event) {
      if (!mounted) return;
      if (event is! Map) return;

      final String type = event['type'];
      final dynamic data = event['data'];
      debugPrint("[MEASURE] Received event: type='$type', data=$data");
      
      // Update UI if we get status updates
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
          setState(() {}); // Trigger repaint
        }
      }
      
      // If we receive the expected result event, store data and finish
      if (type == expectedEvent) {
        debugPrint("[MEASURE] *** Got expected event '$expectedEvent' — finishing measurement");
        if (data is Map) {
          _lastData = Map<String, dynamic>.from(data);
        } else {
          _lastData = {'value': data};
        }
        _finishMeasurement();
        return;
      }
      
      // Also capture ecgResult even if expectedEvent didn't match (safety)
      if (type == 'ecgResult' && widget.type == MeasurementType.ecg) {
        debugPrint("[MEASURE] Got ecgResult (direct match) — storing data and finishing");
        if (data is Map) {
          _lastData = Map<String, dynamic>.from(data);
        } else {
          _lastData = {'value': data};
        }
        _finishMeasurement();
        return;
      }
      
      // ECG fallback: if the device signals STOPPED but we haven't received ecgResult yet,
      // give a 3-second grace period then finish with whatever data we have
      if (type == 'ecgMode' && data == 'STOPPED' && widget.type == MeasurementType.ecg) {
        debugPrint("[MEASURE] ECG STOPPED signal received — starting 3s grace timer");
        _continuousTimer?.cancel();
        _continuousTimer = Timer(const Duration(seconds: 3), () {
          if (mounted && !_isFinished && !_isUploading) {
            debugPrint("[MEASURE] Grace timer expired — finishing ECG with data: $_lastData");
            _finishMeasurement();
          }
        });
      }
    });

    // 3. For continuous sensors (oxyParam, temp), use a 10s collection window.
    //    For ECG: wait for ecgResult or ecgMode STOPPED, but set a 60s absolute max.
    //    For BP: no timer needed — bpResult is a discrete event.
    if (widget.type == MeasurementType.ecg) {
      // Absolute max timeout for ECG — safety net so user is never stuck
      _continuousTimer = Timer(const Duration(seconds: 60), () {
        if (mounted && !_isFinished && !_isUploading) {
          debugPrint("[MEASURE] 60s ECG max timeout — force finishing");
          _finishMeasurement();
        }
      });
    } else if (expectedEvent != 'bpResult') {
      _continuousTimer = Timer(const Duration(seconds: 10), () {
        if (mounted && !_isFinished && !_isUploading) {
          debugPrint("[MEASURE] 10s continuous timer expired — finishing");
          _finishMeasurement();
        }
      });
    }
  }

  void _finishMeasurement() async {
    // Guard: only run once
    if (_isFinished || _isUploading) return;
    _isFinished = true;
    debugPrint("[MEASURE] _finishMeasurement called. _lastData=$_lastData");
    
    _continuousTimer?.cancel();
    _lepuSubscription?.cancel();
    
    // Stop hardware
    try {
      switch (widget.type) {
        case MeasurementType.bloodPressure: await LepuService.stopBp(); break;
        case MeasurementType.ecg: await LepuService.stopEcg(); break;
        case MeasurementType.glucose:
        case MeasurementType.oxygen:
        case MeasurementType.heartRate:
        case MeasurementType.temperature:
          // No explicit stop command needed
          break;
      }
    } catch (e) {
      debugPrint("[MEASURE] Error stopping measurement: $e");
    }

    if (!mounted) return;
    
    // If _lastData is still null (ecgResult never arrived), create fallback data
    if (_lastData == null) {
      debugPrint("[MEASURE] WARNING: _lastData is null — using fallback data");
      switch (widget.type) {
        case MeasurementType.ecg:
          _lastData = {'hr': 0, 'result': 0, 'resultMess': 'تم القياس - لم يتم استلام النتيجة من الجهاز'};
          break;
        default:
          _lastData = {'value': 0};
          break;
      }
    }

    // --- ZERO MEASUREMENT VALIDATION ---
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
        _isFinished = false; // Reset so they can try again
        _lastData = null;
      });
      _speakText('النتيجة صفر، يرجى إعادة المحاولة');
      
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            textDirection: TextDirection.rtl,
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text('تنبيه', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            ],
          ),
          content: const Text(
            'لم يتم التقاط أي قراءة (النتيجة صفر). يرجى التأكد من استخدام الجهاز بشكل صحيح والمحاولة مرة أخرى.',
            textDirection: TextDirection.rtl,
            style: TextStyle(fontFamily: 'Cairo', fontSize: 16),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(
                  context,
                  AppRouter.measurementInstruction,
                  arguments: {
                    'type': widget.type,
                    'remainingTypes': widget.remainingTypes,
                  },
                );
              },
              child: const Text('المحاولة مرة أخرى', style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ],
        ),
      );
      return;
    }
    // --- END VALIDATION ---

    setState(() {
      _isUploading = true;
    });
    _speakText('جاري حفظ النتائج وتحليلها');

    // Attach full ECG wave list for backend storage
    if (widget.type == MeasurementType.ecg && _ecgPoints.isNotEmpty) {
      _lastData ??= {};
      _lastData!['ecg_wave'] = _ecgPoints;
    }

    // Save locally (this is synchronous, always works)
    MeasurementStore().updateMeasurement(widget.type, _lastData);
    
    // Also save ECG wave data if this is an ECG measurement
    if (widget.type == MeasurementType.ecg && _ecgPoints.isNotEmpty) {
      MeasurementStore().updateEcgWaveData(
        _ecgPoints,
        resultMessage: _lastData?['resultMess']?.toString(),
        diagnosisResult: _lastData?['result'] is int ? _lastData!['result'] : null,
      );
      debugPrint("[MEASURE] Saved ${_ecgPoints.length} ECG wave points to store");
    }
    debugPrint("[MEASURE] Saved locally. Posting to backend...");
    
    // Post to backend database — wrapped in try/catch so navigation always happens
    try {
      await VitalsService().postVitals(widget.type, _lastData ?? {});
      debugPrint("[MEASURE] Backend post succeeded");
    } catch (e) {
      debugPrint("[MEASURE] Backend post failed (non-blocking): $e");
    }

    if (!mounted) return;

    debugPrint("[MEASURE] Navigating to result screen or next measurement");
    
    if (widget.remainingTypes != null && widget.remainingTypes!.isNotEmpty) {
      // Show a temporary success state before moving to the next measurement
      setState(() {
        _isUploading = false;
        _isFinished = true;
        _finalStatus = 'success';
        _finalInstruction = 'تم اكتمال ${widget.type.title} بنجاح. سيتم الانتقال للقياس التالي...';
      });
      _speakText(_finalInstruction!);

      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          final nextType = widget.remainingTypes!.first;
          final nextRemaining = widget.remainingTypes!.sublist(1);
          
          Navigator.pushReplacementNamed(
            context,
            AppRouter.measurementInstruction,
            arguments: {
              'type': nextType,
              'remainingTypes': nextRemaining,
            },
          );
        }
      });
    } else {
      // Auto-navigate to result screen if it's the last or only measurement
      Navigator.pushReplacementNamed(
        context,
        AppRouter.measurementResult,
        arguments: {
          'type': widget.type,
          'resultData': _lastData,
        },
      );
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _lepuSubscription?.cancel();
    _continuousTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFF65418F);

    return MeasurementLayout(
      title: widget.type.title,
      child: Row(
        children: [
          // Left Side - Device Image
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
                'assets/images/measurements/icons/${widget.type.name}.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_not_supported,
                  size: 100,
                  color: Colors.grey,
                ),
              ),
            ),
          ),

          // Right Side - Measuring Progress
          Expanded(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isUploading)
                  const Column(
                    children: [
                      CircularProgressIndicator(color: primaryColor),
                      SizedBox(height: 20),
                      Text(
                        'جاري حفظ النتائج وتحليلها...',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ],
                  )
                else if (_isFinished)
                  Column(
                    children: [
                      // Added image to the final step
                      Container(
                        margin: const EdgeInsets.only(bottom: 24),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: (_finalStatus == 'alert' 
                              ? const Color(0xFFEB5757) 
                              : const Color(0xFF27AE60)).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Image.asset(
                          'assets/images/measurements/icons/${widget.type.name}.png',
                          width: 60,
                          height: 60,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.check_circle_outline,
                            size: 60,
                            color: _finalStatus == 'alert' ? const Color(0xFFEB5757) : const Color(0xFF27AE60),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                        decoration: BoxDecoration(
                          color: _finalStatus == 'alert' 
                              ? const Color(0xFFEB5757).withOpacity(0.1)
                              : const Color(0xFF27AE60).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _finalStatus == 'alert' 
                                ? const Color(0xFFEB5757)
                                : const Color(0xFF27AE60),
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              MeasurementStore().getMeasurement(widget.type).value,
                              style: TextStyle(
                                fontSize: 64,
                                fontWeight: FontWeight.bold,
                                color: _finalStatus == 'alert' 
                                  ? const Color(0xFFEB5757)
                                  : const Color(0xFF27AE60),
                              ),
                            ),
                            Text(
                              MeasurementStore().getMeasurement(widget.type).unit,
                              style: TextStyle(
                                fontSize: 24,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _finalInstruction ?? '',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: _finalStatus == 'alert' 
                            ? const Color(0xFFEB5757)
                            : Colors.grey.shade800,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: 250,
                        height: 55,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              AppRouter.dashboard,
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            "العودة للرئيسية",
                            style: TextStyle(fontSize: 22, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  )
                else if (widget.type == MeasurementType.ecg)
                  Container(
                    height: 160,
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.teal.withOpacity(0.3)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CustomPaint(
                        painter: EcgPainter(
                          dataPoints: _ecgPoints,
                        ),
                      ),
                    ),
                  )
                else
                  ScaleTransition(
                    scale: _pulseAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF85A1).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Image.asset(
                        'assets/images/measurements/icons/${widget.type.name}.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.favorite,
                          size: 60,
                          color: Color(0xFFFF85A1),
                        ),
                      ),
                    ),
                  ),
                
                if (!_isFinished && !_isUploading) ...[
                  const SizedBox(height: 40),
                  const Text(
                    'انتظر بهدوء',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'لا تتحدث أو تتحرك حتى ينتهي القياس',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      color: Color(0xFF2D2340),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          color: Color(0xFFFF85A1),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _status,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
