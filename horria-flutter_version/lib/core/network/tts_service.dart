import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_config.dart';

class TtsService {
  static Future<void> speak(String text) async {
    try {
      await http.post(
        Uri.parse('${ApiConfig.baseUrl}/diagnosis/speak'),
        headers: {"Content-Type": "application/json"},
        body: json.encode({"text": text}),
      );
    } catch (e) {
      print('Error speaking text: $e');
    }
  }
}
