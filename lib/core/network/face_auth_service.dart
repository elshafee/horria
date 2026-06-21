import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'api_config.dart';

/// Represents the result from the backend face verification endpoint.
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
      isSuccess: json['session_id'] != null,
      token: json['session_id']?.toString(), // Use session_id as token
      userId: json['user']?['id'] is int ? json['user']['id'] : int.tryParse(json['user']?['id']?.toString() ?? ''),
      errorMessage: json['detail']?.toString(),
      userName: json['user']?['name']?.toString(),
      greeting: json['greeting']?.toString(),
    );
  }
}

/// Gateway service for transmitting tablet camera frames to the remote CPU-bound verification endpoint.
class FaceAuthService {
  // Configurable base URL, ideally loaded from an environment config file
  final String baseUrl;

  FaceAuthService({
    // Pointing to the physical mini-PC orchestrator
    this.baseUrl = ApiConfig.baseUrl,
  });

  /// Transmits image bytes to the backend `/api/auth/face` endpoint for verification.
  /// 
  /// Returns an [AuthResult] containing the session token if verification succeeds.
  Future<AuthResult> verifyFace(List<int> imageBytes) async {
    final client = HttpClient();
    
    try {
      final uri = Uri.parse('$baseUrl/auth/face-login-image');
      final request = await client.postUrl(uri);

      // Set headers for JSON payload
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');

      // Convert image to base64 and add to JSON body
      final base64Image = base64Encode(imageBytes);
      final jsonPayload = jsonEncode({
        'image': base64Image,
      });
      request.add(utf8.encode(jsonPayload));

      // Await backend response
      final response = await request.close();
      
      // Read response body
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
        return AuthResult.fromJson(jsonMap);
      } else {
        String? errorMessage;
        try {
          final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
          errorMessage = jsonMap['detail']?.toString();
        } catch (_) {}
        
        return AuthResult(
          isSuccess: false,
          errorMessage: errorMessage ?? 'Server returned status code: ${response.statusCode}.',
        );
      }
    } catch (e) {
      // Catch network timeouts or socket exceptions
      return AuthResult(
        isSuccess: false,
        errorMessage: 'Network exception occurred during face verification: $e',
      );
    } finally {
      client.close();
    }
  }
}
