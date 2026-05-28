import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // 1. Identify the FlutterViewController.
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController

    // 2. Create the FlutterMethodChannel with the unique channel name.
    let batteryChannel = FlutterMethodChannel(name: "samples.flutter.dev/battery",
                                              binaryMessenger: controller.binaryMessenger)

    // 3. Set a handler to receive messages from Flutter.
    batteryChannel.setMethodCallHandler({
      [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in

      // Check if the requested method name is "getBatteryLevel".
      guard call.method == "getBatteryLevel" else {
        // If the method is unknown, return 'notImplemented'.
        result(FlutterMethodNotImplemented)
        return
      }

      // Call our helper function to get the actual battery level.
      self?.receiveBatteryLevel(result: result)
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  /// Helper function to interact with iOS (UIKit) and get the battery level.
  private func receiveBatteryLevel(result: FlutterResult) {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true

    // Check if the battery level can actually be read.
    if device.batteryState == .unknown {
      // Send an error back to Flutter.
      result(FlutterError(code: "UNAVAILABLE",
                          message: "Battery level not available.",
                          details: nil))
    } else {
      // device.batteryLevel returns a float from 0.0 to 1.0 (e.g., 0.95 for 95%).
      // We convert it to a rounded Int (0 to 100) to send back to Flutter.
      result(Int(device.batteryLevel * 100))
    }
  }
}
