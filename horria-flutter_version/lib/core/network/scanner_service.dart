import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'auth_store.dart';
import 'api_config.dart';

class ScannerResult {
  final bool isSuccess;
  final String status;
  final String message;
  final List<Map<String, dynamic>> parsedResults;

  ScannerResult({
    required this.isSuccess,
    required this.status,
    required this.message,
    required this.parsedResults,
  });
}

class ScannerService {
  final String? _explicitBaseUrl;
  String get baseUrl => _explicitBaseUrl ?? ApiConfig.baseUrl;

  ScannerService({
    String? baseUrl,
  }) : _explicitBaseUrl = baseUrl;

  /// Sends a request to trigger the backend lab scanner and OCR pipeline.
  Future<ScannerResult> scanLabResults() async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 120); // Scanning takes time

    try {
      final uri = Uri.parse('$baseUrl/lab/scan');
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      final userId = AuthStore().userId;
      final sessionId = AuthStore().sessionId;

      if (userId == null) {
        return ScannerResult(
          isSuccess: false,
          status: 'error',
          message: 'المستخدم غير مسجل الدخول',
          parsedResults: [],
        );
      }

      final payload = {
        'user_id': userId,
        'session_id': sessionId ?? "demo_session",
      };

      final jsonString = jsonEncode(payload);
      request.add(utf8.encode(jsonString));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsedResultsRaw = jsonMap['parsed_results'] as List<dynamic>?;
        final parsedResults = parsedResultsRaw
            ?.map((e) => e as Map<String, dynamic>)
            .toList() ?? [];

        return ScannerResult(
          isSuccess: true,
          status: 'success',
          message: 'تم فحص المستند بنجاح',
          parsedResults: parsedResults,
        );
      } else {
        return ScannerResult(
          isSuccess: false,
          status: 'error',
          message: jsonMap['detail']?.toString() ?? 'حدث خطأ أثناء فحص المستند',
          parsedResults: [],
        );
      }
    } catch (e) {
      debugPrint("Scanner post error: $e");
      return ScannerResult(
        isSuccess: false,
        status: 'error',
        message: 'حدث خطأ في الاتصال بالخادم',
        parsedResults: [],
      );
    } finally {
      client.close();
    }
  }
}
