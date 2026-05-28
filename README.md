# Horria — Lepu PC303 Medical Dashboard

> A professional-grade Flutter application for real-time vital sign monitoring via the Lepu/Creative Medical PC303 multi-parameter Bluetooth monitor.

---

## Overview

**Horria_T** is a clinical-quality mobile dashboard that bridges the Lepu BlePro native SDK with a modern Flutter UI. It delivers continuous, high-fidelity visualization of ECG waveforms, SpO₂, heart rate, perfusion index, and blood pressure — all without requiring any manual device pairing.

Built for fixed-device deployments such as dedicated clinical stations or home-care setups, the app connects automatically to a pre-configured hardware address at startup and streams telemetry in real time.

---

## Screenshots

> *(Add screenshots of the ECG monitor, vital signs dashboard, and data log console here.)*

---

## Architecture

Horria_T follows a **Hybrid Native Bridge** pattern:

```
┌──────────────────────────────────┐
│         Flutter / Dart           │  UI Layer
│  Dark-mode dashboard · ECG graph │
│  Vital signs · Data log console  │
└────────────┬─────────────────────┘
             │  MethodChannel  (commands)
             │  EventChannel   (telemetry stream)
┌────────────▼─────────────────────┐
│        Android / Kotlin          │  Protocol Layer
│  lepu-blepro-1.3.1 AAR           │
│  GATT connection · MTU mgmt      │
│  Medical protocol translation    │
└──────────────────────────────────┘
```

| Layer | Responsibility |
|---|---|
| **UI (Flutter/Dart)** | Real-time graphing, vital sign display, data logging, UX |
| **Bridge** | `MethodChannel` for command calls; `EventChannel` for high-frequency telemetry |
| **Native (Kotlin)** | Bluetooth GATT, MTU negotiation, Lepu SDK integration, protocol decoding |

---

## Features

### 🔗 Automatic Fixed-MAC Connection
The app is hardcoded to connect to a specific device MAC address (`20:22:04:00:4E:13`), bypassing manual scanning entirely. On launch, pairing is immediate and fully automatic — no user intervention required.

### 📈 Real-time ECG Visualization
A high-performance custom-painted ECG monitor with:
- **Right-to-left sweep** — newest data enters on the right, mirroring clinical monitor conventions
- **Full-width medical grid** — edge-to-edge background grid for accurate waveform reading
- **1000-point rolling buffer** — smooth, high-fidelity waveform rendering with no perceptible lag

### 💓 Live Telemetry Dashboard
Continuously monitored vital signs:
| Metric | Description |
|---|---|
| **SpO₂** | Blood oxygen saturation (%) |
| **Heart Rate** | Beats per minute (BPM) |
| **PI** | Perfusion Index — pulse strength indicator |
| **Blood Pressure** | Systolic / Diastolic and Mean Arterial Pressure (MAP) |

### 🗒 Comprehensive Data Log
A timestamped technical console capturing all raw data packets and hardware status updates from the native SDK — useful for debugging, audit trails, and clinical state analysis.

---

## Technical Stack

| Component | Technology |
|---|---|
| **Framework** | Flutter 3.x |
| **Native Language** | Kotlin (JVM 17) |
| **Native SDK** | Lepu BlePro v1.3.1 |
| **Bluetooth Stack** | `no.nordicsemi.android:ble` |
| **Event Bus** | `io.github.jeremyliao:live-event-bus-x` |
| **Internal Logging** | `io.getstream:stream-log-android` |
| **Permissions** | `com.guolindev.permissionx` |

### Android Permissions Required
- `BLUETOOTH_CONNECT` / `BLUETOOTH_SCAN` (Android 12+)
- `ACCESS_FINE_LOCATION`
- Foreground Service (for stable background monitoring)

---

## Getting Started

### Prerequisites
- Flutter SDK 3.x installed
- Android Studio with NDK support
- Android device running API 23+ (Bluetooth LE required)
- Lepu/Creative Medical PC303 device

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/your-username/horria_t.git
   cd horria_t
   ```

2. **Place the native SDK AAR**
   Copy `lepu-blepro-1.3.1.aar` into:
   ```
   android/app/libs/
   ```

3. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```

4. **(Optional) Update the target MAC address**
   If connecting to a different PC303 unit, update the hardcoded address in the native bridge:
   ```kotlin
   // android/app/src/main/kotlin/.../MainActivity.kt
   private val TARGET_MAC = "20:22:04:00:4E:13"
   ```

5. **Run the application**
   ```bash
   flutter run
   ```

---

## How It Works

1. On app launch, the Flutter layer calls `initSdk` via `MethodChannel`.
2. The Kotlin layer initialises the Lepu BlePro SDK with `MODEL_CMI_PC303` configuration.
3. The native layer immediately begins scanning for and connecting to the fixed MAC address.
4. Once connected, the app starts a **Foreground Service** to maintain the Bluetooth connection in the background.
5. Incoming telemetry (ECG packets, SpO₂ readings, BP results) is pushed through the `EventChannel` to Dart, where it is decoded and rendered in real time.

---

## Project Structure

```
horria_t/
├── lib/
│   ├── main.dart                  # App entry point
│   ├── screens/
│   │   └── dashboard_screen.dart  # Main monitoring dashboard
│   ├── widgets/
│   │   ├── ecg_painter.dart       # Custom ECG canvas renderer
│   │   └── vitals_panel.dart      # SpO₂ / HR / PI / BP widgets
│   └── services/
│       └── device_bridge.dart     # MethodChannel + EventChannel interface
├── android/
│   └── app/
│       ├── libs/                  # lepu-blepro-1.3.1.aar (not committed)
│       └── src/main/kotlin/
│           └── MainActivity.kt    # Native bridge, SDK init, BLE management
└── pubspec.yaml
```

---

## Known Limitations & Roadmap

- [ ] Currently optimised for **PC303 only** (`MODEL_CMI_PC303`); multi-device support planned
- [ ] MAC address is hardcoded; a settings screen for configuring the target device is on the roadmap
- [ ] iOS support is not implemented (Android-only BLE stack)
- [ ] Data export (CSV / PDF report generation) is a planned feature

---

## Contributing

Contributions, bug reports, and feature requests are welcome. Please open an issue before submitting a pull request so the change can be discussed first.

---

## License

This project is licensed under the [MIT License](LICENSE).

---

## Acknowledgements

- [Lepu Medical / Creative Medical](https://www.lepumedical.com/) for the PC303 hardware and BlePro SDK
- [Nordic Semiconductor](https://github.com/NordicSemiconductor/Android-BLE-Library) for the Android BLE Library
- The Flutter and open-source Android community
