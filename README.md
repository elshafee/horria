# Horria — Real-time Medical Monitoring Dashboard

> A professional-grade Flutter application for real-time vital sign monitoring via the Lepu PC303 multi-parameter Bluetooth monitor. Engineered for clinical deployments with high-fidelity ECG visualization, continuous telemetry streaming, and comprehensive data logging.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)](https://flutter.dev)
[![Kotlin](https://img.shields.io/badge/Kotlin-JVM%2017-purple?logo=kotlin)](https://kotlinlang.org)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Platform](https://img.shields.io/badge/Platform-Android%2023%2B-brightgreen)](https://www.android.com)

---

## 📋 Overview

**Horria** is a clinical-grade medical monitoring dashboard that bridges the Lepu BlePro native SDK with a modern Flutter UI layer. It delivers continuous, high-fidelity visualization of:

- **ECG Waveforms** — Real-time cardiac rhythms with medical-grade grid visualization
- **Vital Signs** — SpO₂, heart rate, perfusion index, and blood pressure (systolic/diastolic/MAP)
- **Data Logging** — Comprehensive timestamped telemetry for clinical audit trails and diagnostics
- **Automatic Connectivity** — Fixed-device mode with pre-configured MAC address for seamless deployment

Optimized for dedicated clinical stations, telemedicine hubs, and home-care monitoring systems.

---

## 🏗️ Architecture

Horria employs a **Hybrid Native Bridge** pattern, decoupling the Flutter UI layer from low-level Bluetooth protocol handling:

```
┌──────────────────────────────────────────┐
│         Flutter / Dart                   │  🎨 UI Layer
│  Dark-mode dashboard                     │
│  ECG graph · Vital signs · Data console  │
└────────────┬─────────────────────────────┘
             │
             ├─ MethodChannel  (commands)
             ├─ EventChannel   (telemetry stream)
             │
┌────────────▼─────────────────────────────┐
│        Android / Kotlin                  │  🔌 Protocol Layer
│  Lepu BlePro SDK v1.3.1                  │
│  GATT connection · MTU negotiation       │
│  Medical protocol decoding               │
└──────────────────────────────────────────┘
             │
┌────────────▼─────────────────────────────┐
│        Bluetooth LE Hardware              │  📡 Device Layer
│  Lepu PC303 Multi-Parameter Monitor      │
│  ECG · SpO₂ · BP sensors                 │
└──────────────────────────────────────────┘
```

| Layer | Responsibility |
|-------|-----------------|
| **UI (Flutter/Dart)** | Real-time graphing, vital sign display, data logging, responsive UX |
| **Bridge (MethodChannel/EventChannel)** | Async command execution and high-frequency telemetry stream routing |
| **Native (Kotlin)** | Bluetooth GATT stack, MTU negotiation, Lepu SDK integration, medical protocol decoding |
| **Hardware (Bluetooth)** | PC303 device communication and sensor data transmission |

---

## ✨ Features

### 🔗 Automatic Fixed-MAC Connection
- Hardcoded device MAC address (`20:22:04:00:4E:13`) for repeatable, zero-configuration deployments
- Immediate pairing on app launch — no manual scanning or user intervention required
- Ideal for fixed-location clinical installations

### 📈 High-Performance ECG Visualization
A custom-painted medical-grade ECG monitor featuring:
- **Right-to-left sweep** — Newest data enters from the right, mirroring clinical monitor conventions
- **Full-width medical grid** — Edge-to-edge gridlines for precise waveform interpretation
- **1000-point rolling buffer** — Smooth, high-fidelity rendering with <100ms latency
- **Zero visual lag** — Optimized CustomPainter and frame scheduling

### 💓 Live Vital Signs Dashboard
Continuously monitored and displayed metrics:

| Metric | Unit | Description |
|--------|------|-------------|
| **SpO₂** | % | Blood oxygen saturation (normal: 95–100%) |
| **Heart Rate** | BPM | Beats per minute (normal: 60–100 BPM) |
| **PI** | % | Perfusion Index — pulse amplitude indicator (normal: 1–10%) |
| **Systolic BP** | mmHg | Upper pressure reading (normal: 90–120 mmHg) |
| **Diastolic BP** | mmHg | Lower pressure reading (normal: 60–80 mmHg) |
| **MAP** | mmHg | Mean Arterial Pressure — average pressure over a cardiac cycle |

### 🗒️ Comprehensive Data Log
- Timestamped technical console capturing all raw data packets
- Hardware status updates and event notifications
- Exportable logs for clinical audits, debugging, and post-hoc analysis
- Real-time filtering and search capabilities

### 🔋 Background Monitoring
- Foreground Service integration for stable, continuous Bluetooth connection
- Survives app backgrounding and system resource constraints
- Automatic reconnection on connection loss

---

## 🛠️ Technical Stack

| Component | Technology | Version |
|-----------|-----------|---------|
| **Framework** | Flutter | 3.x |
| **Language** | Dart | Latest |
| **Native Bridge** | Kotlin | JVM 17 |
| **Bluetooth SDK** | Lepu BlePro | v1.3.1 |
| **BLE Stack** | Nordic Semiconductor Android BLE Library | Latest |
| **Event Bus** | LiveEventBus-X | — |
| **Logging** | Stream Log Android | — |
| **Permissions** | PermissionX | — |

### 📦 Language Composition
- **HTML** 62.7% (web assets / configuration)
- **C++** 11.9% (native library bindings)
- **CMake** 9.3% (native build system)
- **Dart** 7.1% (Flutter application logic)
- **Kotlin** 6.6% (Android native bridge)
- **Swift** 1.7% (iOS support — future)
- **Other** 0.7% (config, documentation)

### 🔐 Required Android Permissions
```xml
<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />     <!-- API 31+ -->
<uses-permission android:name="android.permission.BLUETOOTH_SCAN" />        <!-- API 31+ -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.FOREGROUND_SERVICE" />
```

---

## 🚀 Getting Started

### Prerequisites
- **Flutter SDK** 3.x or later ([install](https://flutter.dev/docs/get-started/install))
- **Android Studio** with NDK support
- **Android Device** running API 23+ with Bluetooth LE capability
- **Lepu PC303** multi-parameter monitor
- **Git** for version control

### Installation

#### 1. Clone the Repository
```bash
git clone https://github.com/elshafee/horria.git
cd horria
```

#### 2. Install Native Dependencies
Copy the Lepu BlePro SDK AAR into the Android libs directory:
```bash
cp path/to/lepu-blepro-1.3.1.aar android/app/libs/
```

#### 3. Resolve Flutter Dependencies
```bash
flutter pub get
```

#### 4. (Optional) Configure Target Device MAC Address
If connecting to a different PC303 unit, update the hardcoded MAC address:

**File:** `android/app/src/main/kotlin/.../MainActivity.kt`
```kotlin
private val TARGET_MAC = "20:22:04:00:4E:13"  // Replace with your device's MAC
```

#### 5. Build & Deploy
```bash
flutter run
```

Or, to build a release APK:
```bash
flutter build apk --release
```

---

## 📖 How It Works

### Initialization Flow
1. **App Launch** → Flutter calls `initSdk()` via `MethodChannel`
2. **SDK Initialization** → Kotlin layer configures Lepu BlePro with `MODEL_CMI_PC303`
3. **Auto-Connect** → Native layer scans for and connects to the fixed MAC address
4. **Foreground Service** → Connection maintained in background with system notification
5. **Telemetry Stream** → Incoming ECG packets, SpO₂, BP data pushed via `EventChannel` to Dart
6. **Real-time Rendering** → Flutter UI decodes and displays vital signs and ECG waveform

### Data Flow Diagram
```
PC303 Device
    ↓ (Bluetooth LE GATT)
Android Native (Kotlin)
    ├─ GATT connection management
    ├─ MTU negotiation
    └─ Medical protocol decoding
    ↓ (EventChannel)
Flutter / Dart UI
    ├─ Real-time ECG rendering
    ├─ Vital signs display
    ├─ Data logging & persistence
    └─ User interaction
```

---

## 📁 Project Structure

```
horria/
├── lib/
│   ├── main.dart                           # Application entry point
│   ├─��� models/
│   │   ├── vital_signs.dart                # Data models for ECG, SpO₂, BP, HR
│   │   └── device_state.dart               # Connection and device state management
│   ├── screens/
│   │   ├── dashboard_screen.dart           # Main monitoring dashboard UI
│   │   ├── splash_screen.dart              # App initialization screen
│   │   └── settings_screen.dart            # Configuration & logs
│   ├── widgets/
│   │   ├── ecg_painter.dart                # Custom Canvas ECG renderer
│   │   ├── vitals_panel.dart               # Vital signs display components
│   │   ├── data_log_console.dart           # Real-time log viewer
│   │   └── connection_indicator.dart       # Device connection status widget
│   └── services/
│       ├── device_bridge.dart              # MethodChannel & EventChannel interface
│       ├── data_parser.dart                # Medical data protocol parsing
│       └── storage_service.dart            # Local data persistence
├── android/
│   └── app/
│       ├── libs/
│       │   └── lepu-blepro-1.3.1.aar       # Native Lepu SDK (not committed)
│       └── src/main/kotlin/com/horria/
│           ├── MainActivity.kt             # Native bridge, BLE management, SDK init
│           ├── BleService.kt               # Bluetooth connection service
│           ├── ProtocolDecoder.kt          # Medical data protocol decoding
│           └── ForegroundService.kt        # Background monitoring service
├── ios/
│   └── Runner/
│       └── GeneratedPluginRegistrant.m     # (iOS support: future implementation)
├── pubspec.yaml                            # Flutter dependencies and metadata
├── README.md                               # This file
├── LICENSE                                 # MIT License
└── .gitignore                              # Git exclusions (AAR files, build artifacts)
```

---

## 🔄 Workflow & Usage

### Typical User Journey
1. **Launch App** → Device auto-connects to pre-configured PC303 monitor
2. **View Dashboard** → Real-time ECG, SpO₂, HR, BP, PI displayed
3. **Monitor Telemetry** → Continuous streaming without user action
4. **Review Logs** → Access timestamped data packets for audit/debugging
5. **Close App** → Background service stops gracefully

### For Developers
1. **Modify Kotlin Bridge** → Edit `MainActivity.kt` or `ProtocolDecoder.kt` to change BLE behavior
2. **Update Dart UI** → Modify `dashboard_screen.dart` or add new widgets
3. **Test Changes** → Deploy via `flutter run` to Android device
4. **Export Logs** → Use data_log_console to inspect raw protocol packets

---

## ⚠️ Known Limitations & Roadmap

| Feature | Status | Notes |
|---------|--------|-------|
| PC303 Support | ✅ Implemented | Currently optimized for PC303 only |
| Multi-Device Support | 🔲 Planned | Support for additional Lepu monitors in roadmap |
| Configurable MAC Address | 🔲 Planned | Settings UI for runtime device selection |
| iOS Support | 🔲 Future | Android-only at present; iOS bridge architecture designed |
| Data Export (CSV/PDF) | 🔲 Planned | Clinical report generation feature |
| Cloud Sync | 🔲 Researching | HIPAA-compliant cloud data synchronization |

---

## 🐛 Troubleshooting

### Connection Issues
- **Device not found**: Ensure PC303 is powered on and within Bluetooth range
- **Frequent disconnections**: Check Android device Bluetooth settings; disable battery optimization for the app
- **Permission denied**: Grant `BLUETOOTH_CONNECT`, `BLUETOOTH_SCAN`, and `ACCESS_FINE_LOCATION` permissions

### Performance Issues
- **Lag in ECG rendering**: Reduce dashboard refresh rate or close background apps
- **High CPU usage**: Check system monitor; reduce EventChannel polling frequency in native code

### Build Issues
- **AAR not found**: Verify `lepu-blepro-1.3.1.aar` is in `android/app/libs/`
- **Gradle sync fails**: Run `flutter clean` and `flutter pub get`

For additional support, open an [issue](https://github.com/elshafee/horria/issues).

---

## 🤝 Contributing

We welcome contributions from the community! Please follow these guidelines:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/my-feature`
3. **Commit** with clear messages: `git commit -m "Add ECG smoothing algorithm"`
4. **Push** to your fork: `git push origin feature/my-feature`
5. **Open** a Pull Request with a detailed description

**Before submitting**, please:
- Open an [issue](https://github.com/elshafee/horria/issues) to discuss your change
- Ensure code follows Dart/Kotlin style guidelines
- Test thoroughly on Android 23+ devices
- Update documentation as needed

---

## 📄 License

This project is licensed under the **[MIT License](LICENSE)** — see the [LICENSE](LICENSE) file for details.

---

## 🙏 Acknowledgements

- **[Lepu Medical / Creative Medical](https://www.lepumedical.com/)** — PC303 hardware and BlePro SDK
- **[Nordic Semiconductor](https://github.com/NordicSemiconductor/Android-BLE-Library)** — Android BLE Library
- **[Flutter & Dart Teams](https://flutter.dev)** — Framework and language
- **Open-source community** — For libraries, tools, and inspiration

---

## 📞 Support & Contact

- **Issues**: [GitHub Issues](https://github.com/elshafee/horria/issues)
- **Discussions**: [GitHub Discussions](https://github.com/elshafee/horria/discussions)
- **Email**: [Contact via GitHub profile](https://github.com/elshafee)

---

**Last Updated:** 2026 | **Status:** Active Development