import 'package:flutter/material.dart';
import 'package:horria_t/auth/auth_main.dart';
import 'package:horria_t/onboarding/splash_screen.dart';
import 'auth/login/login_screen.dart';
import 'auth/register/register.dart';
import 'dashboard/dashboard.dart';
import 'ecg_painter.dart';
import 'lepu_service.dart';
import 'onboarding/select_language.dart';

void main() {
  runApp(const LepuApp());
}

class LepuApp extends StatelessWidget {
  const LepuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lepu PC303 Dashboard',
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.teal,
        colorScheme: const ColorScheme.dark(
          primary: Colors.tealAccent,
          secondary: Colors.teal,
        ),
        useMaterial3: true,
      ),
      routes: {
        '/splash' : (context) => SplashScreen(),
        '/language' : (context) => LanguageSelectionScreen(),
        '/main_auth' : (context) => AuthMainScreen(),
        '/login' : (context) => LoginScreen(),
        '/register' : (context) => const RegisterScreen(),
        '/dashboard' : (context) => const HomeScreen(),
      },
      home: const SplashScreen(),
      // home: const HomeScreen(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String _status = 'Disconnected';
  String _battery = '--%';

  // Telemetry Data
  int _heartRate = 0;
  int _spo2 = 0;
  double _pi = 0.0;
  String _bpResult = '-- / --';

  final List<double> _ecgPoints = [];
  final int _maxEcgPoints = 1000; // Large enough to fill any screen width

  final List<Map<String, dynamic>> _logs = [];
  final int _maxLogs = 50;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _addLog(String type, dynamic data) {
    setState(() {
      _logs.insert(0, {
        'timestamp': DateTime.now(),
        'type': type,
        'data': data.toString(),
      });
      if (_logs.length > _maxLogs) {
        _logs.removeLast();
      }
    });
  }

  void _initStream() {
    LepuService.listenToUpdates().listen((event) {
      if (event is! Map) return;
      final String type = event['type'];
      final dynamic data = event['data'];

      // Don't log every single ECG wave point to keep the log readable
      if (type != 'ecgWave') {
        _addLog(type, data);
      }

      setState(() {
        switch (type) {
          case 'status':
            _status = data.toString();
            break;
          case 'ecgWave':
            final List<dynamic> points = data['floats'];
            for (var p in points) {
              _ecgPoints.add(p.toDouble());
            }
            if (_ecgPoints.length > _maxEcgPoints) {
              _ecgPoints.removeRange(0, _ecgPoints.length - _maxEcgPoints);
            }
            break;
          case 'oxyParam':
            _spo2 = data['spo2'] ?? 0;
            _heartRate = data['pr'] ?? 0;
            _pi = (data['pi'] ?? 0.0).toDouble();
            break;
          case 'bpResult':
            _bpResult = "${data['sys']} / ${data['dia']}";
            if (data['pr'] != null) _heartRate = data['pr'];
            break;
          default:
            // Handle any other data types by just updating the log (already handled by _addLog)
            break;
        }
      });
    }, onError: (err) {
      setState(() => _status = "Error: $err");
    });
  }

  Future<void> _refreshBattery() async {
    try {
      final level = await LepuService.getBatteryLevel();
      setState(() => _battery = "$level%");
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PC303 Dashboard'),
        actions: [
          Center(child: Text('Battery: $_battery  ', style: const TextStyle(fontSize: 12))),
          IconButton(onPressed: _refreshBattery, icon: const Icon(Icons.battery_std)),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildStatusHeader(),
            const SizedBox(height: 20),
            _buildEcgSection(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("SpO2", "$_spo2%", Icons.water_drop, Colors.blue)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("Heart Rate", "$_heartRate BPM", Icons.favorite, Colors.red)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _buildMetricCard("BP (Sys/Dia)", _bpResult, Icons.speed, Colors.orange)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildMetricCard("PI", _pi.toStringAsFixed(1), Icons.line_style, Colors.purple)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildActionButtons(),
                  const SizedBox(height: 32),
                  _buildDataLog(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataLog() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Data Log", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton(
              onPressed: () => setState(() => _logs.clear()),
              child: const Text("Clear"),
            ),
          ],
        ),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.2)),
          ),
          child: _logs.isEmpty
              ? const Center(child: Text("No data received yet", style: TextStyle(color: Colors.grey)))
              : ListView.separated(
                  padding: const EdgeInsets.all(8),
                  itemCount: _logs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white10),
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    final time = "${log['timestamp'].hour}:${log['timestamp'].minute}:${log['timestamp'].second}";
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text("[$time]", style: const TextStyle(color: Colors.tealAccent, fontSize: 10, fontFamily: 'monospace')),
                              const SizedBox(width: 8),
                              Text(log['type'].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.orangeAccent)),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(log['data'], style: const TextStyle(fontSize: 11, color: Colors.white70, fontFamily: 'monospace')),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatusHeader() {
    bool isConnected = _status.contains("Connected");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isConnected ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isConnected ? Colors.green : Colors.red),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 12, color: isConnected ? Colors.green : Colors.red),
          const SizedBox(width: 8),
          Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildEcgSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text("Real-time ECG", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        Container(
          height: 220,
          width: double.infinity,
          color: Colors.black,
          child: CustomPaint(
            painter: EcgPainter(
              dataPoints: List.from(_ecgPoints),
              gainScale: 150.0,
              pixelsPerSample: 1.2,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton("Connect", Icons.bluetooth, Colors.teal, () => LepuService.initSdk()),
            _buildActionButton("Start ECG", Icons.play_arrow, Colors.green, () => LepuService.startEcg()),
            _buildActionButton("Stop ECG", Icons.stop, Colors.red, () => LepuService.stopEcg()),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton("Start BP", Icons.monitor_heart, Colors.orange, () => LepuService.startBp()),
            _buildActionButton("Stop BP", Icons.stop_circle, Colors.deepOrange, () => LepuService.stopBp()),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withOpacity(0.2),
        foregroundColor: color,
        side: BorderSide(color: color),
      ),
    );
  }
}
