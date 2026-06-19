import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:uuid/uuid.dart';

import '../../core/network/auth_store.dart';
import '../../core/routes/app_router.dart';
import '../../models/measurement_type.dart';
import '../../models/diagnosis_result.dart';
import '../measurements/measurement_popup_dialog.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
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
  List<String> _currentOptions = [];
  bool _isThinking = false;
  
  final ScrollController _scrollController = ScrollController();

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
    final wsUrl = Uri.parse('ws://192.168.1.9:8000/ws/$_sessionId/$userId');
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
      // Streamed sentence for TTS, we can ignore or show it typing
    } else if (response['type'] == 'done') {
      setState(() {
        _isThinking = false;
        
        // Sometimes the 'response' text itself isn't in 'done', but wait, the backend currently
        // doesn't send the full text in 'done'. It only sends next_action, options, etc.
        // Let's rely on the sentence chunks or just know that in our updated backend, 
        // the LLM response is fully generated on the backend.
        // Ah, the backend currently sends 'type': 'sentence' with 'text', 
        // but 'done' only has next_action, options, etc.
        // We need to capture the sentences.
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
        // Collect sentences
        // Since we want to display the full response as one bubble, let's append it
        // Or just add a new message if the last one was user
        setState(() {
            if (_messages.isNotEmpty && !_messages.last.isUser) {
                // Append
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
    
    // Simulate sending data back (in real app, use VitalsService/MeasurementStore)
    // For now we tell the backend we finished
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
      backgroundColor: const Color(0xFFF9F7FA),
      appBar: AppBar(
        title: const Text('د. حورية - التقييم الطبي'),
        backgroundColor: const Color(0xFF65418F),
        foregroundColor: Colors.white,
      ),
      body: Directionality(
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
                    return const Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  
                  final msg = _messages[index];
                  return Align(
                    alignment: msg.isUser ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.75,
                      ),
                      decoration: BoxDecoration(
                        color: msg.isUser ? const Color(0xFF65418F) : Colors.white,
                        borderRadius: BorderRadius.circular(16).copyWith(
                          bottomRight: msg.isUser ? const Radius.circular(16) : const Radius.circular(0),
                          bottomLeft: msg.isUser ? const Radius.circular(0) : const Radius.circular(16),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        msg.text,
                        style: TextStyle(
                          fontSize: 16,
                          color: msg.isUser ? Colors.white : Colors.black87,
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
                height: 60,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _currentOptions.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final option = _currentOptions[index];
                    return ActionChip(
                      label: Text(option),
                      backgroundColor: const Color(0xFFFF85A1).withOpacity(0.1),
                      side: const BorderSide(color: Color(0xFFFF85A1)),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: _toggleListening,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: _isListening ? Colors.redAccent : const Color(0xFFFF85A1),
                          shape: BoxShape.circle,
                          boxShadow: [
                            if (_isListening)
                              BoxShadow(
                                color: Colors.redAccent.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              )
                          ],
                        ),
                        child: Icon(
                          _isListening ? Icons.mic : Icons.mic_none,
                          color: Colors.white,
                          size: 32,
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
    );
  }
}
