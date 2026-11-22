import 'dart:convert';
import 'dart:io';
import 'api_config.dart';

/// Represents the result of an authentication operation (e.g. signup).
class AuthResult {
  final bool isSuccess;
  final String? token;
  final int? userId;
  final String? errorMessage;
  final String? userName;
  final String? greeting;

  AuthResult({
    required this.isSuccess,
    this.token,
    this.userId,
    this.errorMessage,
    this.userName,
    this.greeting,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      isSuccess: json['user'] != null || json['status'] == 'ok',
      token: json['session_id']?.toString() ?? json['user_id']?.toString(),
      userId: json['user']?['id'] is int ? json['user']['id'] : int.tryParse(json['user']?['id']?.toString() ?? json['user_id']?.toString() ?? ''),
      errorMessage: json['detail']?.toString() ?? json['message']?.toString(),
      userName: json['user']?['name']?.toString(),
      greeting: json['greeting']?.toString(),
    );
  }
}

class AuthService {
  final String? _explicitBaseUrl;
  String get baseUrl => _explicitBaseUrl ?? ApiConfig.baseUrl;

  AuthService({
    String? baseUrl,
  }) : _explicitBaseUrl = baseUrl;

  /// Signs up a new user with their personal info, face image, and medical history.
  Future<AuthResult> signup({
    required String name,
    required String phone,
    required int age,
    required String gender,
    required List<int> imageBytes,
    required Map<String, dynamic> medicalHistory,
  }) async {
    final client = HttpClient();

    try {
      final uri = Uri.parse('$baseUrl/auth/signup-image');
      final request = await client.postUrl(uri);

      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      String? base64Image;
      if (imageBytes.isNotEmpty) {
        base64Image = base64Encode(imageBytes);
      }

      // Map Flutter's gender string to backend format
      final sex = gender == 'ذكر' ? 'male' : 'female';

      final payload = {
        'name': name,
        'phone': phone,
        'age': age,
        'sex': sex,
        if (base64Image != null) 'image': base64Image,
        'medical_history': medicalHistory,
      };

      final jsonString = jsonEncode(payload);
      request.add(utf8.encode(jsonString));

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;

      if (response.statusCode == 200 || response.statusCode == 201) {
        return AuthResult.fromJson(jsonMap);
      } else {
        return AuthResult(
          isSuccess: false,
          errorMessage: jsonMap['detail']?.toString() ?? 'فشل التسجيل',
        );
      }
    } catch (e, stackTrace) {
      print('AuthService Exception: $e');
      print('Stacktrace: $stackTrace');
      return AuthResult(
        isSuccess: false,
        errorMessage: 'حدث خطأ في الاتصال: $e',
      );
    } finally {
      client.close();
    }
  }
}
