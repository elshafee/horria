import 'dart:convert';
import 'dart:io';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:flutter/foundation.dart';

class ApiConfig {
  static String _serverIp = '192.168.0.183'; // Default fallback
  
  static String get serverIp => _serverIp;
  static String get baseUrl => 'http://$_serverIp:8000';
  static String get wsUrl  => 'ws://$_serverIp:8000';
  static String get n8nWebhookUrl => 'http://$_serverIp:5678/webhook/hema-assistant';
  static String get legacyBaseUrl => 'http://$_serverIp:5000';

  static final _networkInfo = NetworkInfo();



  /// Scans the local network for the server by checking port 8000 on each IP.
  static Future<bool> scanAndSetServerIp() async {
    debugPrint('Starting network scan for server...');
    
    // Explicitly using the requested subnet
    final String subnet = '192.168.0';
    debugPrint('Subnet identified: $subnet.0/24');

    // Parallel scanning
    final List<Future<String?>> scanTasks = [];
    for (int i = 1; i < 255; i++) {
      final String targetIp = '$subnet.$i';
      scanTasks.add(_checkIp(targetIp));
    }

    final results = await Future.wait(scanTasks);
    final String? foundIp = results.firstWhere((ip) => ip != null, orElse: () => null);

    if (foundIp != null) {
      _serverIp = foundIp;
      debugPrint('=========================================');
      debugPrint('SUCCESS: Server found and set to: $_serverIp');
      debugPrint('=========================================');
      return true;
    }

    debugPrint('FAILED: Server not found on local network.');
    return false;
  }

  /// Verifies if a specific IP is hosting the server by checking the /health endpoint.
  static Future<String?> _checkIp(String ip) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(milliseconds: 1000);
      final request = await client.getUrl(Uri.parse('http://$ip:8000/health'));
      final response = await request.close();
      
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        // Be more flexible with the verification string
        if (responseBody.contains('"status":"ok"') || 
            responseBody.contains('Orchestrator')) {
          return ip;
        }
      }
      return null;
    } catch (e) {
      return null;
    } finally {
      client?.close();
    }
  }
}
