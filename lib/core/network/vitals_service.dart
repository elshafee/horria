import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../models/measurement_type.dart';
import 'auth_store.dart';

class VitalsResult {
  final bool isSuccess;
  final String status;
  final String message;
  final String? audioBase64;

  VitalsResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    this.audioBase64,
  });
}

class VitalsService {
  final String baseUrl;

  VitalsService({
    this.baseUrl = 'http://192.168.1.9:8000',
  });

  /// Sends the latest measurement data to the backend database.
  Future<VitalsResult> postVitals(MeasurementType type, Map<String, dynamic> data) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);

    try {
      final uri = Uri.parse('$baseUrl/vitals');
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final userId = AuthStore().userId;
      final sessionId = AuthStore().sessionId;

      double? parseDouble(dynamic v) {
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }

      final payload = {
        'user_id': userId,
        'session_id': sessionId ?? "demo_session",
        'language': 'ar', // Required by the backend
      };

      // Map Flutter sensor keys to Backend keys
      switch (type) {
        case MeasurementType.bloodPressure:
          payload['sys'] = parseDouble(data['sys']);
          payload['dia'] = parseDouble(data['dia']);
          break;
        case MeasurementType.heartRate:
        case MeasurementType.ecg:
          payload['hr'] = parseDouble(data['pr'] ?? data['hr'] ?? data['value']);
          if (data.containsKey('ecg_wave')) {
            payload['ecg_wave'] = data['ecg_wave'];
          }
          break;
        case MeasurementType.oxygen:
          payload['spo2'] = parseDouble(data['spo2'] ?? data['value']);
          break;
        case MeasurementType.temperature:
          payload['temp'] = parseDouble(data['temp'] ?? data['value']);
          break;
        case MeasurementType.glucose:
          // Glucose isn't currently tracked in the Python backend vitals schema
          // but we send it anyway so it doesn't crash
          break;
      }

      final jsonString = jsonEncode(payload);
      request.add(utf8.encode(jsonString));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return VitalsResult(
          isSuccess: true,
          status: jsonMap['status']?.toString() ?? 'ok',
          message: jsonMap['message']?.toString() ?? 'تم حفظ القراءات بنجاح',
          audioBase64: jsonMap['audio_base64']?.toString(),
        );
      } else {
        return VitalsResult(
          isSuccess: false,
          status: 'error',
          message: jsonMap['detail']?.toString() ?? 'حدث خطأ أثناء حفظ القراءات',
        );
      }
    } catch (e) {
      debugPrint("Vitals post error: $e");
      return VitalsResult(
        isSuccess: false,
        status: 'error',
        message: 'حدث خطأ في الاتصال بالخادم',
      );
    } finally {
      client.close();
    }
  }

  /// Fetches historical vitals data for the current user.
  Future<List<Map<String, dynamic>>> getHistory() async {
    final userId = AuthStore().userId;
    if (userId == null) return [];

    final client = HttpClient();
    try {
      final uri = Uri.parse('$baseUrl/vitals/history/$userId');
      final request = await client.getUrl(uri);
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();

      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(responseBody);
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
    } catch (e) {
      debugPrint("Vitals history error: $e");
    } finally {
      client.close();
    }
    return [];
  }

  /// Triggers a physical print job on the backend orchestrator
  Future<bool> printAssessment({String? clinicName}) async {
    final userId = AuthStore().userId;
    final sessionId = AuthStore().sessionId;
    
    debugPrint("=== PRINT ASSESSMENT REQUEST ===");
    debugPrint("UserId: $userId");
    debugPrint("SessionId: $sessionId");

    if (userId == null || sessionId == null) {
      debugPrint("Error: userId or sessionId is null. Cannot print.");
      debugPrint("================================");
      return false;
    }

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('$baseUrl/print-assessment');
      debugPrint("URL: $uri");
      final request = await client.postUrl(uri);
      
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      
      final payload = {
        'user_id': userId,
        'session_id': sessionId,
        if (clinicName != null) 'clinic_name': clinicName,
      };
      
      debugPrint("Payload: ${jsonEncode(payload)}");
      request.add(utf8.encode(jsonEncode(payload)));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: $responseBody");
      debugPrint("================================");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Print assessment exception error: $e");
      debugPrint("================================");
      return false;
    } finally {
      client.close();
    }
  }

  /// Sends ECG wave data to the orchestrator for thermal printing
  Future<bool> printEcgStrip({
    required List<double> wavePoints,
    int? heartRate,
    String? diagnosis,
  }) async {
    debugPrint("=== PRINT ECG STRIP REQUEST ===");
    debugPrint("Wave points count: ${wavePoints.length}");

    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 10);
    try {
      final uri = Uri.parse('$baseUrl/print-ecg');
      final request = await client.postUrl(uri);
      
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      
      final payload = {
        'wave_points': wavePoints,
        'heart_rate': heartRate,
        'diagnosis': diagnosis,
      };
      
      request.add(utf8.encode(jsonEncode(payload)));
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      debugPrint("Response Status Code: ${response.statusCode}");
      debugPrint("Response Body: $responseBody");
      debugPrint("================================");

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint("Print ECG strip exception error: $e");
      debugPrint("================================");
      return false;
    } finally {
      client.close();
    }
  }
}
