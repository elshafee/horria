import 'package:flutter/services.dart';

class LepuService {
  static const lepuCommands = MethodChannel('com.example.lepu/commands');
  static const lepuStream = EventChannel('com.example.lepu/stream');
  static const batteryChannel = MethodChannel('samples.flutter.dev/battery');

  static Future<void> initSdk() async {
    await lepuCommands.invokeMethod('initLepuSdk');
  }

  static Future<void> connectToDevice(String mac) async {
    await lepuCommands.invokeMethod('connectToDevice', {'mac': mac});
  }

  static Future<void> startEcg() async {
    await lepuCommands.invokeMethod('startEcg');
  }

  static Future<void> stopEcg() async {
    await lepuCommands.invokeMethod('stopEcg');
  }

  static Future<void> startBp() async {
    await lepuCommands.invokeMethod('startBp');
  }

  static Future<void> stopBp() async {
    await lepuCommands.invokeMethod('stopBp');
  }

  static Future<int> getBatteryLevel() async {
    return await batteryChannel.invokeMethod('getBatteryLevel');
  }

  static Stream listenToUpdates() {
    return lepuStream.receiveBroadcastStream();
  }
}
