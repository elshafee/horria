import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/auth_store.dart';
import '../../core/network/api_config.dart';
import '../../core/routes/app_router.dart';
import '../../models/measurement_type.dart';
import '../../models/diagnosis_result.dart';
import '../measurements/measurement_popup_dialog.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay) % 1.0;
            final offset = value < 0.5 ? Curves.easeInOut.transform(value * 2) : Curves.easeInOut.transform((1 - value) * 2);
            return Transform.translate(
              offset: Offset(0, -5 * offset),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF65418F),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

class RippleAnimation extends StatefulWidget {
  final Widget child;
  final bool isAnimating;
  const RippleAnimation({super.key, required this.child, required this.isAnimating});

  @override
  State<RippleAnimation> createState() => _RippleAnimationState();
}

class _RippleAnimationState extends State<RippleAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.isAnimating) _controller.repeat();
  }

  @override
  void didUpdateWidget(RippleAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isAnimating != oldWidget.isAnimating) {
      if (widget.isAnimating) {
        _controller.repeat();
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            if (widget.isAnimating)
              Transform.scale(
                scale: 1.0 + (_controller.value * 0.5),
                child: Opacity(
                  opacity: 1.0 - _controller.value,
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            widget.child,
          ],
        );
      },
    );
  }
}

class AiInterviewScreen extends StatefulWidget {
  const AiInterviewScreen({super.key});

  @override
  State<AiInterviewScreen> createState() => _AiInterviewScreenState();
}

class _AiInterviewScreenState extends State<AiInterviewScreen> {
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  
  late WebSocketChannel _channel;
  final String _sessionId = const Uuid().v4();
  
  final List<ChatMessage> _messages = [];
  List<String> _currentOptions = [
    "أشعر بألم في الصدر",
    "خفقان في القلب",
    "ضيق في التنفس",
    "دوار أو دوخة"
  ];
  bool _isThinking = false;
  
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _connectWebSocket();
  }

  void _initSpeech() async {
    await _speech.initialize();
  }

  void _connectWebSocket() {
    final userId = AuthStore().userId ?? 1; // Default to 1 if not logged in
    final wsUrl = Uri.parse('${ApiConfig.wsUrl}/ws/$_sessionId/$userId');
    _channel = WebSocketChannel.connect(wsUrl);

    _channel.stream.listen(
      (data) {
        final Map<String, dynamic> response = jsonDecode(data);
        _handleServerResponse(response);
      },
      onError: (error) {
        print("WebSocket Error: $error");
        _addMessage("حدث خطأ في الاتصال بالخادم. يرجى المحاولة لاحقاً.", false);
        setState(() => _isThinking = false);
      },
      onDone: () {
        print("WebSocket Connection Closed");
      },
    );

    // Initial greeting trigger by sending a blank or start context
    _sendMessage("أهلاً دكتورة حورية، أنا مريض جديد واحتاج لاستشارة طبية.");
  }

  void _handleServerResponse(Map<String, dynamic> response) {
    if (response['type'] == 'sentence') {
      // Streamed sentence for TTS
    } else if (response['type'] == 'done') {
      setState(() {
        _isThinking = false;
      });
      
      final nextAction = response['next_action'];
      
      if (response.containsKey('options')) {
        setState(() {
          _currentOptions = List<String>.from(response['options'] ?? []);
        });
      }

      if (nextAction == 'GO_TO_VITALS_SCREEN') {
        final controlCommand = response['control_command'];
        _triggerVitalMeasurement(controlCommand);
      } else if (nextAction == 'SHOW_DIAGNOSES') {
        final List<dynamic> rawDiagnoses = response['differential_diagnoses'] ?? [];
        final report = DiagnosisReport(
          robotMessage: "بناءً على الأعراض التي ذكرتها، قمت بتحليل حالتك وهذه هي أقرب الاحتمالات.",
          results: rawDiagnoses.map((r) => DiagnosisResult.fromMap(r as Map<String, dynamic>)).toList(),
        );

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.pushReplacementNamed(
              context, 
              AppRouter.diagnosisResults, 
              arguments: report
            );
          }
        });
      }
    } else if (response['type'] == 'sentence') {
        setState(() {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
                final last = _messages.removeLast();
                _messages.add(ChatMessage(text: "${last.text} ${response['text']}", isUser: false));
            } else {
                _messages.add(ChatMessage(text: response['text'], isUser: false));
            }
        });
        _scrollToBottom();
    }
  }

  Future<void> _triggerVitalMeasurement(String? command) async {
    MeasurementType type = MeasurementType.heartRate; // Default
    if (command == 'START_LEPU_BP') type = MeasurementType.bloodPressure;
    if (command == 'START_LEPU_ECG') type = MeasurementType.ecg;
    
    // Show Popup
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => MeasurementPopupDialog(type: type),
    );
    
    _channel.sink.add(jsonEncode({
      "type": "sensor_data",
      "data": {
        "hr": 85,
        "spo2": 98,
        "sys": 125,
        "dia": 82,
        "temp": 37.1
      }
    }));
    setState(() => _isThinking = true);
  }

  void _sendMessage(String text) {
    if (text.isEmpty) return;
    
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _currentOptions.clear();
      _isThinking = true;
    });
    
    _scrollToBottom();
    
    _channel.sink.add(jsonEncode({
      "type": "text",
      "message": text
    }));
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: isUser));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleListening() async {
    if (!_isListening) {
      bool available = await _speech.initialize();
      if (available) {
        setState(() => _isListening = true);
        _speech.listen(
          localeId: "ar_EG",
          onResult: (result) {
            if (result.finalResult) {
              setState(() => _isListening = false);
              _sendMessage(result.recognizedWords);
            }
          },
        );
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  @override
  void dispose() {
    _channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('د. حورية - التقييم الطبي', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: const Color(0xFF65418F),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.white.withOpacity(0.9), Colors.white.withOpacity(0.5)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF5EFFF), Color(0xFFFFF0F5)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length + (_isThinking ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length && _isThinking) {
                        return Align(
                          alignment: Alignment.centerRight,
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TweenAnimationBuilder<double>(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              tween: Tween<double>(begin: 0, end: 1),
                              builder: (context, value, child) {
                                return Transform.translate(
                                  offset: Offset(0, 10 * (1 - value)),
                                  child: Opacity(opacity: value, child: child),
                                );
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.85),
                                  borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(20),
                                    topRight: Radius.circular(20),
                                    bottomLeft: Radius.circular(20),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.04),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                                ),
                                child: const TypingIndicator(),
                              ),
                            ),
                          ),
                        );
                      }
                      
                      final msg = _messages[index];
                      return TweenAnimationBuilder<double>(
                        key: ValueKey('msg_${index}_${msg.text.hashCode}'),
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOutCubic,
                        tween: Tween<double>(begin: 0, end: 1),
                        builder: (context, value, child) {
                          return Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: Opacity(opacity: value, child: child),
                          );
                        },
                        child: Align(
                          alignment: msg.isUser ? Alignment.centerLeft : Alignment.centerRight,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                            constraints: BoxConstraints(
                              maxWidth: MediaQuery.of(context).size.width * 0.78,
                            ),
                            decoration: BoxDecoration(
                              gradient: msg.isUser
                                  ? const LinearGradient(
                                      colors: [Color(0xFF65418F), Color(0xFF8E54E9)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    )
                                  : LinearGradient(
                                      colors: [Colors.white.withOpacity(0.95), Colors.white.withOpacity(0.85)],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              borderRadius: BorderRadius.circular(20).copyWith(
                                bottomRight: msg.isUser ? const Radius.circular(20) : const Radius.circular(0),
                                bottomLeft: msg.isUser ? const Radius.circular(0) : const Radius.circular(20),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: msg.isUser
                                      ? const Color(0xFF65418F).withOpacity(0.3)
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              msg.text,
                              style: TextStyle(
                                fontSize: 16,
                                color: msg.isUser ? Colors.white : const Color(0xFF2D2D2D),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                if (_currentOptions.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    height: 65,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _currentOptions.length,
                      separatorBuilder: (context, index) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final option = _currentOptions[index];
                        return ActionChip(
                          label: Text(option, style: const TextStyle(fontWeight: FontWeight.w600)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                          backgroundColor: Colors.white.withOpacity(0.9),
                          side: const BorderSide(color: Color(0xFFFF85A1), width: 1.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                          elevation: 2,
                          shadowColor: const Color(0xFFFF85A1).withOpacity(0.2),
                          onPressed: () => _sendMessage(option),
                        );
                      },
                    ),
                  ),

                // Bottom Input Area
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        offset: const Offset(0, -5),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            style: const TextStyle(fontSize: 16),
                            decoration: InputDecoration(
                              hintText: 'اكتب أعراضك هنا...',
                              hintStyle: TextStyle(color: Colors.grey.shade400),
                              filled: true,
                              fillColor: const Color(0xFFF9F7FA),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(30),
                                borderSide: BorderSide.none,
                              ),
                              suffixIcon: IconButton(
                                icon: const Icon(Icons.send, color: Color(0xFF65418F)),
                                onPressed: () {
                                  if (_textController.text.trim().isNotEmpty) {
                                    _sendMessage(_textController.text.trim());
                                    _textController.clear();
                                  }
                                },
                              ),
                            ),
                            onSubmitted: (text) {
                              if (text.trim().isNotEmpty) {
                                _sendMessage(text.trim());
                                _textController.clear();
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: _toggleListening,
                          child: RippleAnimation(
                            isAnimating: _isListening,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isListening
                                      ? [Colors.redAccent, Colors.deepOrangeAccent]
                                      : [const Color(0xFFFF85A1), const Color(0xFFFF6B8B)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: (_isListening ? Colors.redAccent : const Color(0xFFFF85A1)).withOpacity(0.4),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                    offset: const Offset(0, 5),
                                  )
                                ],
                              ),
                              child: Icon(
                                _isListening ? Icons.mic : Icons.mic_none,
                                color: Colors.white,
                                size: 28,
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
          ),
        ),
      ),
    );
  }
}
