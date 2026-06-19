import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import '../../lepu_service.dart';
import '../measurements/measurement_layout.dart';

class DiagnosesScreen extends StatefulWidget {
  const DiagnosesScreen({super.key});

  @override
  State<DiagnosesScreen> createState() => _DiagnosesScreenState();
}

class _DiagnosesScreenState extends State<DiagnosesScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  WebSocket? _socket;
  bool _isConnected = false;
  String _themeState = "normal"; // normal, abnormal, emergency
  String _statusMessage = "متصل بدكتورة حورية";
  
  final List<Map<String, dynamic>> _messages = [];
  List<Map<String, dynamic>> _sduiComponents = [];
  bool _isSpeaking = false;
  String _currentSpeechSentence = "";

  @override
  void initState() {
    super.initState();
    _connectWebSocket();
  }

  void _connectWebSocket() async {
    setState(() => _statusMessage = "جاري الاتصال بالخادم...");
    try {
      // Connecting to the physical orchestrator
      final wsUrl = "ws://192.168.1.9:8000/ws/session_diag_123/1";
      _socket = await WebSocket.connect(wsUrl);
      
      setState(() {
        _isConnected = true;
        _statusMessage = "متصل بالعيادة الذكية";
        _messages.add({
          "sender": "agent",
          "text": "مرحباً بك في شاشة التشخيص الطبي. أنا دكتورة حورية، يرجى وصيف عوارضك أو طرح استفسارك للاطمئنان على صحتك."
        });
      });

      _socket!.listen(
        (message) {
          final data = jsonDecode(message);
          _handleIncomingMessage(data);
        },
        onError: (error) {
          setState(() {
            _isConnected = false;
            _statusMessage = "خطأ في الاتصال بالخادم";
          });
        },
        onDone: () {
          setState(() {
            _isConnected = false;
            _statusMessage = "تم قطع الاتصال بالخادم";
          });
        },
      );
    } catch (e) {
      setState(() {
        _isConnected = false;
        _statusMessage = "فشل الاتصال بالخادم: $e";
      });
    }
  }

  void _handleIncomingMessage(Map<String, dynamic> data) {
    final type = data['type'];

    if (type == "sentence") {
      final text = data['text'] as String;
      setState(() {
        _isSpeaking = true;
        _currentSpeechSentence = text;
      });
      // In a real app, play base64 audio via player:
      // final audioB64 = data['audio_base64'];
      // playAudioBytes(base64Decode(audioB64));
    } 
    
    else if (type == "done") {
      final nextAction = data['next_action'];
      final themeState = data['theme_state'] ?? "normal";
      final controlCommand = data['control_command'] ?? "NONE";
      final sduiComps = data['sdui_components'] as List<dynamic>? ?? [];

      setState(() {
        _isSpeaking = false;
        _themeState = themeState;
        _sduiComponents = List<Map<String, dynamic>>.from(sduiComps);
        
        // Save conversation response to list
        if (_currentSpeechSentence.isNotEmpty) {
          _messages.add({
            "sender": "agent",
            "text": _currentSpeechSentence
          });
          _currentSpeechSentence = "";
        }
      });

      _scrollToBottom();
      _handleControlCommand(controlCommand);
      
      // Handle special navigation actions
      if (nextAction == "SHOW_EMERGENCY_ALERT") {
        // Automatically pop up emergency dialogue or push emergency overlay
        // Navigator.pushNamed(context, '/emergency');
      }
    }
  }

  void _handleControlCommand(String command) {
    if (command == "START_LEPU_BP") {
      _triggerHardwareSensor("blood_pressure");
    } else if (command == "START_LEPU_ECG") {
      _triggerHardwareSensor("ecg");
    }
  }

  void _triggerHardwareSensor(String sensorType) async {
    setState(() => _statusMessage = "جاري تشغيل مستشعر $sensorType تلقائياً...");
    
    try {
      if (sensorType == "blood_pressure") {
        await LepuService.startBp();
      } else {
        await LepuService.startEcg();
      }
      
      // Listen to raw readings from method channel stream
      LepuService.listenToUpdates().listen((event) {
        if (event is Map && event['type'] == 'bpResult' && sensorType == "blood_pressure") {
          final data = event['data'];
          // Send raw readings directly back to the LLM agent via WebSocket
          _socket?.add(jsonEncode({
            "type": "sensor_data",
            "sensor": "blood_pressure",
            "data": {
              "sys": data['sys'] ?? 118,
              "dia": data['dia'] ?? 76,
              "hr": data['pr'] ?? 72,
              "temp": 36.7,
              "spo2": 98
            }
          }));
          setState(() => _statusMessage = "تم إرسال قياس الضغط للخادم.");
        }
      });
    } catch (e) {
      setState(() => _statusMessage = "خطأ أثناء تشغيل المستشعر: $e");
    }
  }

  void _sendMessage() {
    final text = _textController.text.trim();
    if (text.isEmpty || !_isConnected) return;

    setState(() {
      _messages.add({
        "sender": "user",
        "text": text
      });
      _textController.clear();
    });

    _scrollToBottom();

    // Send payload over WebSocket
    _socket?.add(jsonEncode({
      "type": "text",
      "message": text
    }));
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

  Color _getThemeColor() {
    switch (_themeState) {
      case "abnormal":
        return const Color(0xFFFFF9E6); // Light yellow tint
      case "emergency":
        return const Color(0xFFFDF2F2); // Light red tint
      case "normal":
      default:
        return const Color(0xFFF3FAF6); // Light green tint
    }
  }

  Color _getThemeBorderColor() {
    switch (_themeState) {
      case "abnormal":
        return const Color(0xFFF39C12); // Amber
      case "emergency":
        return const Color(0xFFE74C3C); // Red
      case "normal":
      default:
        return const Color(0xFF2ECC71); // Green
    }
  }

  Widget _buildSduiComponent(Map<String, dynamic> comp) {
    final type = comp['type'];

    if (type == "WarningCard") {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFDF2F2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE74C3C), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Color(0xFFE74C3C)),
                const SizedBox(width: 8),
                Text(
                  comp['title'] ?? 'تحذير طبي',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFFE74C3C)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comp['message'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ],
        ),
      );
    } 
    
    else if (type == "DrugCard") {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF3498DB), width: 1.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication, color: Color(0xFF3498DB)),
                const SizedBox(width: 8),
                Text(
                  comp['drug_name'] ?? 'دواء مقترح',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF3498DB)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comp['instructions'] ?? '',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      );
    } 
    
    else if (type == "AdviceCard") {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2ECC71), width: 1.5),
        ),
        child: Text(
          comp['text'] ?? '',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  void dispose() {
    _socket?.close();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MeasurementLayout(
      title: 'التشخيص الطبي والاستشارة',
      sidebarSelectedIndex: 2, // Highlight the records/diagnoses tab
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Row(
          children: [
            // Left Column: SDUI dynamic component rendering & status
            Expanded(
              flex: 1,
              child: Container(
                margin: const EdgeInsets.only(left: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _getThemeColor(),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _getThemeBorderColor(), width: 2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Heading
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'لوحة التوجيهات الطبية',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D2340),
                          ),
                        ),
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _isConnected ? Colors.green : Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const Divider(height: 24),

                    // Dynamic SDUI components list
                    Expanded(
                      child: _sduiComponents.isEmpty
                          ? Center(
                              child: Text(
                                'تحدث مع الدكتورة حورية للبدء في التشخيص وعرض إرشادات جمعية القلب الأمريكية (AHA).',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey.shade500, height: 1.5),
                              ),
                            )
                          : ListView.builder(
                              itemCount: _sduiComponents.length,
                              itemBuilder: (context, index) {
                                return _buildSduiComponent(_sduiComponents[index]);
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),

            // Right Column: Chat layout terminal
            Expanded(
              flex: 1,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10),
                  ],
                ),
                child: Column(
                  children: [
                    // Chat Messages
                    Expanded(
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isUser = msg['sender'] == "user";

                          return Align(
                            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              decoration: BoxDecoration(
                                color: isUser ? const Color(0xFF65418F) : const Color(0xFFF1EEF5),
                                borderRadius: BorderRadius.circular(16).copyWith(
                                  bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                                  bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                                ),
                              ),
                              child: Text(
                                msg['text'] ?? '',
                                style: TextStyle(
                                  fontSize: 15,
                                  color: isUser ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Current streamed sentence block (thinking/speaking notice)
                    if (_isSpeaking && _currentSpeechSentence.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF85A1).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              "حورية تتحدث: $_currentSpeechSentence",
                              style: const TextStyle(fontSize: 13, color: Color(0xFFFF85A1), fontWeight: FontWeight.w500),
                            ),
                          ),
                        ),
                      ),

                    const Divider(height: 1),

                    // Message input field bar
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _textController,
                              onSubmitted: (_) => _sendMessage(),
                              decoration: const InputDecoration(
                                hintText: 'اكتب رسالتك هنا...',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.symmetric(horizontal: 16),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: _sendMessage,
                            icon: const Icon(Icons.send, color: Color(0xFF65418F)),
                          ),
                        ],
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
