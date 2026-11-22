import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'core/network/api_config.dart';

void main() {
  runApp(MyApp());
}

// =========================
// 🚀 APP
// =========================

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: VoiceScreen(),
    );
  }
}

// =========================
// 📱 SCREEN
// =========================
class VoiceScreen extends StatefulWidget {
  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late IO.Socket socket;
  final SpeechToText stt = SpeechToText();
  final SpeakerService speaker = SpeakerService();

  String status = "Idle";
  String lastMessage = "No message yet";
  bool isListening = false;

  @override
  void initState() {
    super.initState();
    initSocket();
  }

  // =========================
  // 🔌 SOCKET
  // =========================
  void initSocket() {
    socket = IO.io(
      ApiConfig.baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .build(),
    );

    socket.onConnect((_) {
      setState(() => status = "Connected");
      print("✅ Connected to Flask");
    });

    socket.onDisconnect((_) {
      setState(() => status = "Disconnected");
    });

    socket.on('ai_response', (data) async {
      String text = data['text'] ?? "";

      print("AI RESPONSE: $text");

      setState(() {
        lastMessage = text;
        status = "Speaking...";
      });

      await speaker.speak(text);

      setState(() {
        status = "Connected";
      });
    });
  }

  // =========================
  // 🎤 START LISTENING
  // =========================
  Future<void> startListening() async {
    bool available = await stt.initialize();

    if (!available) return;

    setState(() {
      isListening = true;
      status = "Listening...";
    });

    stt.listen(
      localeId: "ar_EG",
      listenMode: ListenMode.confirmation,
      onResult: (result) {
        if (result.finalResult) {
          String text = result.recognizedWords;

          setState(() {
            lastMessage = text;
            isListening = false;
            status = "Sending...";
          });

          socket.emit('user_text', {"text": text});
        }
      },
    );
  }

  // =========================
  // 🛑 STOP LISTENING
  // =========================
  void stopListening() {
    stt.stop();
    setState(() {
      isListening = false;
      status = "Idle";
    });
  }

  // =========================
  // UI
  // =========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Dr HEMA Voice AI"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            Text(
              "Status: $status",
              style: TextStyle(color: Colors.white),
            ),

            SizedBox(height: 20),

            Text(
              lastMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
              ),
            ),

            SizedBox(height: 40),

            FloatingActionButton(
              onPressed: isListening ? stopListening : startListening,
              child: Icon(isListening ? Icons.stop : Icons.mic),
            ),
          ],
        ),
      ),
    );
  }
}

// =========================
// 🔊 TTS SERVICE (FIXED)
// =========================
class SpeakerService {
  final FlutterTts tts = FlutterTts();

  bool _isSpeaking = false;

  SpeakerService() {
    init();
  }

  Future<void> init() async {
    await tts.setLanguage("ar-EG");
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);
    await tts.setPitch(1.0);

    tts.setCompletionHandler(() {
      _isSpeaking = false;
    });

    tts.setCancelHandler(() {
      _isSpeaking = false;
    });

    tts.setErrorHandler((msg) {
      print("TTS ERROR: $msg");
      _isSpeaking = false;
    });
  }

  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;

    // ❌ prevent spam calls
    if (_isSpeaking) {
      print("⚠️ TTS busy, skipping");
      return;
    }

    _isSpeaking = true;

    await tts.stop(); // safe reset
    await Future.delayed(Duration(milliseconds: 100));

    await tts.speak(text);
  }
}