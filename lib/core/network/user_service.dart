import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'auth_store.dart';

class UserProfile {
  final int id;
  final String name;
  final int age;
  final String gender;
  final Map<String, String> medicalHistory;

  UserProfile({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.medicalHistory,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final user = json['user'] ?? {};
    final history = json['medical_history'] as Map<String, dynamic>? ?? {};
    
    return UserProfile(
      id: user['id'] ?? 0,
      name: user['name'] ?? '',
      age: user['age'] ?? 0,
      gender: user['sex'] ?? 'unknown',
      medicalHistory: history.map((k, v) => MapEntry(k, v.toString())),
    );
  }
}

class UserService {
  final String baseUrl;

  UserService({
    this.baseUrl = 'http://192.168.1.9:8000',
  });

  Future<UserProfile?> getUserProfile() async {
    final userId = AuthStore().userId;
    if (userId == null) return null;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('$baseUrl/user-profile/$userId');
      final request = await client.getUrl(uri);
      
      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      
      if (response.statusCode == 200) {
        final jsonMap = jsonDecode(responseBody) as Map<String, dynamic>;
        return UserProfile.fromJson(jsonMap);
      }
    } catch (e) {
      debugPrint('Error getting user profile: $e');
    } finally {
      client.close();
    }
    return null;
  }

  Future<bool> updateUserProfile(Map<String, String> updates) async {
    final userId = AuthStore().userId;
    if (userId == null) return false;

    final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
    try {
      final uri = Uri.parse('$baseUrl/update-user-profile');
      final request = await client.postUrl(uri);
      
      request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
      
      final payload = {
        'user_id': userId,
        'updates': updates,
      };
      
      request.add(utf8.encode(jsonEncode(payload)));
      
      final response = await request.close();
      
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      return false;
    } finally {
      client.close();
    }
  }
}
