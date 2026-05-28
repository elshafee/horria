
package com.example.horria_t

import android.Manifest
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothDevice
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.location.LocationManager
import android.os.BatteryManager
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import com.jeremyliao.liveeventbus.LiveEventBus
import com.lepu.blepro.constants.Ble
import com.lepu.blepro.event.EventMsgConst
import com.lepu.blepro.event.InterfaceEvent
import com.lepu.blepro.ext.BleServiceHelper
import com.lepu.blepro.ext.pc303.*
import com.lepu.blepro.objs.Bluetooth
import com.lepu.blepro.objs.BluetoothController
import com.lepu.blepro.observer.BIOL
import com.lepu.blepro.observer.BleChangeObserver
import com.permissionx.guolindev.PermissionX
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity(), BleChangeObserver {

    private val TAG = "MainActivity"

    // Channels definitions
    private val BATTERY_CHANNEL = "samples.flutter.dev/battery"
    private val LEPU_COMMAND_CHANNEL = "com.example.lepu/commands"
    private val LEPU_STREAM_CHANNEL = "com.example.lepu/stream"

    private var eventSink: EventChannel.EventSink? = null
    private var isAutoConnecting = false
    private var connectedModel = Bluetooth.MODEL_PC300

    private val models = intArrayOf(
        Bluetooth.MODEL_PC300, Bluetooth.MODEL_PC300_BLE,
        Bluetooth.MODEL_GM_300SNT, Bluetooth.MODEL_GM_300SNT_BLE,
        Bluetooth.MODEL_CMI_PC303,
    )

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Initialize the Native Event Bus and LEPU SDK hooks
        initEventBus()
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // 1. Existing Battery Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) result.success(batteryLevel)
                else result.error("UNAVAILABLE", "Battery level not available.", null)
            } else {
                result.notImplemented()
            }
        }

        // 2. LEPU Device Controller Method Channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, LEPU_COMMAND_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initLepuSdk" -> {
                    needPermission()
                    result.success("Initialization Started")
                }
                "connectToDevice" -> {
                    val mac = call.argument<String>("mac") ?: ""
                    connectToMac(mac)
                    result.success(true)
                }
                "startEcg" -> {
                    BleServiceHelper.BleServiceHelper.pc300StartEcg(connectedModel)
                    result.success(true)
                }
                "stopEcg" -> {
                    BleServiceHelper.BleServiceHelper.pc300StopEcg(connectedModel)
                    result.success(true)
                }
                "startBp" -> {
                    BleServiceHelper.BleServiceHelper.pc300StartBp(connectedModel)
                    result.success(true)
                }
                "stopBp" -> {
                    BleServiceHelper.BleServiceHelper.pc300StopBp(connectedModel)
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        // 3. LEPU Live Telemetry Event Channel (Streams data up to Dart asynchronous stream listeners)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, LEPU_STREAM_CHANNEL).setStreamHandler(
            object : EventChannel.StreamHandler {
                override fun onListen(arguments: Any?, sink: EventChannel.EventSink?) {
                    eventSink = sink
                    sendToFlutter("status", "Event Channel Connected")
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            }
        )
    }

    // Helper function to safely send structured payloads back to Dart
    private fun sendToFlutter(type: String, data: Any) {
        runOnUiThread {
            eventSink?.success(mapOf("type" to type, "data" to data))
        }
    }

    private fun connectToMac(mac: String) {
        val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            sendToFlutter("status", "Bluetooth not supported")
            return
        }
        
        try {
            val device = adapter.getRemoteDevice(mac)

            // Lepu needs a Bluetooth object which wraps the device and model
            // Constructor: (model, name, device, rssi, scanRecord)
            val bluetooth = Bluetooth(Bluetooth.MODEL_CMI_PC303, device.name ?: "PC303", device, -70, null)

            sendToFlutter("status", "Connecting to $mac...")

            BleServiceHelper.BleServiceHelper.setInterfaces(Bluetooth.MODEL_CMI_PC303)
            lifecycle.addObserver(BIOL(this, intArrayOf(Bluetooth.MODEL_CMI_PC303)))
            BleServiceHelper.BleServiceHelper.stopScan()
            BleServiceHelper.BleServiceHelper.connect(applicationContext, Bluetooth.MODEL_CMI_PC303, device, bluetooth = bluetooth)

            connectedModel = Bluetooth.MODEL_CMI_PC303
            isAutoConnecting = true
        } catch (e: Exception) {
            sendToFlutter("status", "Connection failed: ${e.message}")
        }
    }

    private fun getBatteryLevel(): Int {
        val batteryLevel: Int
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            batteryLevel = batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
        } else {
            val intent = ContextWrapper(applicationContext).registerReceiver(null, IntentFilter(Intent.ACTION_BATTERY_CHANGED))
            batteryLevel = intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(BatteryManager.EXTRA_SCALE, -1)
        }
        return batteryLevel
    }

    // --- LEPU Core Logic ---

    private fun needPermission() {
        val permissions = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        } else if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            arrayOf(
                Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT,
                Manifest.permission.BLUETOOTH_ADVERTISE, Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            )
        } else {
            arrayOf(
                Manifest.permission.ACCESS_COARSE_LOCATION, Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.BLUETOOTH, Manifest.permission.BLUETOOTH_ADMIN
            )
        }

        PermissionX.init(this)
            .permissions(*permissions)
            .onExplainRequestReason { scope, deniedList ->
                scope.showRequestReasonDialog(deniedList, "Bluetooth and Location permissions are required to interface with medical kits", "OK", "Cancel")
            }
            .request { allGranted, _, _ ->
                if (allGranted) checkBt() else sendToFlutter("error", "Permissions Denied")
            }
    }

    private fun checkBt() {
        val adapter = android.bluetooth.BluetoothAdapter.getDefaultAdapter()
        if (adapter == null) {
            sendToFlutter("status", "Bluetooth not supported")
            return
        }
        if (!adapter.isEnabled) {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                if (ActivityCompat.checkSelfPermission(this, Manifest.permission.BLUETOOTH_CONNECT) == PackageManager.PERMISSION_GRANTED) {
                    adapter.enable()
                }
            } else {
                adapter.enable()
            }
        }
        needService()
    }

    private fun needService() {
        var gpsEnabled = false
        val lm = getSystemService(LOCATION_SERVICE) as LocationManager
        try {
            gpsEnabled = lm.isProviderEnabled(LocationManager.GPS_PROVIDER)
        } catch (ex: Exception) { ex.printStackTrace() }

        if (!gpsEnabled) {
            sendToFlutter("status", "Location Service required")
            val myIntent = Intent(Settings.ACTION_LOCATION_SOURCE_SETTINGS)
            startActivityForResult(myIntent, 888)
        } else {
            initService()
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        initService()
    }

    private fun initService() {
        if (BleServiceHelper.BleServiceHelper.checkService()) {
            connectToMac("20:22:04:00:4E:13")
        } else {
            BleServiceHelper.BleServiceHelper.initService(application).initLog(true)
        }
    }

    private fun startScanning() {
        sendToFlutter("status", "Scanning disabled - connecting to fixed device...")
        connectToMac("20:22:04:00:4E:13")
    }

    private fun initEventBus() {
        LiveEventBus.get<Boolean>(EventMsgConst.Ble.EventServiceConnectedAndInterfaceInit)
            .observe(this) { connectToMac("20:22:04:00:4E:13") }

        LiveEventBus.get<Bluetooth>(EventMsgConst.Discovery.EventDeviceFound)
            .observe(this) {
                if (!isAutoConnecting) {
                    isAutoConnecting = true
                    sendToFlutter("status", "Device Found: ${it.name}")

                    BleServiceHelper.BleServiceHelper.setInterfaces(it.model)
                    lifecycle.addObserver(BIOL(this, intArrayOf(it.model)))
                    BleServiceHelper.BleServiceHelper.stopScan()
                    BleServiceHelper.BleServiceHelper.connect(applicationContext, it.model, it.device, bluetooth = it)

                    connectedModel = it.model
                    BluetoothController.clear()
                }
            }

        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceDisconnectReason)
            .observe(this) {
                isAutoConnecting = false
                sendToFlutter("status", "Disconnected")
                startScanning()
            }

        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceReady)
            .observe(this) {
                sendToFlutter("status", "Connected")
                BleServiceHelper.BleServiceHelper.pc300GetInfo(connectedModel)
            }

        // --- Live Telemetry Observers Pipe Directly to Flutter Event Sink ---

        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300RtEcgWave)
            .observe(this) {
                val data = it.data as RtEcgWave
                val ecgData = mapOf(
                    "floats" to data.ecgFloats.toList(),
                    "isProbeOff" to data.isProbeOff,
                    "samplingRate" to 250
                )
                sendToFlutter("ecgWave", ecgData)
            }

        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300RtOxyParam)
            .observe(this) {
                val data = it.data as RtOxyParam
                val oxyData = mapOf(
                    "spo2" to data.spo2,
                    "pr" to data.pr,
                    "pi" to data.pi,
                    "isProbeOff" to data.isProbeOff
                )
                sendToFlutter("oxyParam", oxyData)
            }

        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpResult)
            .observe(this) {
                val data = it.data as BpResult
                val bpData = mutableMapOf(
                    "sys" to data.sys,
                    "dia" to data.dia,
                    "pr" to data.pr
                )
                // map and result might be methods or fields depending on SDK version
                try { bpData["map"] = data.map } catch(e: Exception) {}
                sendToFlutter("bpResult", bpData)
            }

        // --- Error and Hardware State Observers ---

        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceDisconnectReason)
            .observe(this) {
                isAutoConnecting = false
                val reason = when(it) {
                    0 -> "Normal Disconnect"
                    else -> "Error Code: $it"
                }
                sendToFlutter("status", "Disconnected ($reason)")
                startScanning()
            }
        
        /* 
        Note: EventBleErrorMsg seems to be missing in this SDK version (1.3.1).
        If you need error logs, check EventMsgConst.Ble for alternative constants.
        */
    }

    override fun onBleStateChanged(model: Int, state: Int) {
        sendToFlutter("bleState", state == Ble.State.CONNECTED)
    }

    override fun onDestroy() {
        BleServiceHelper.BleServiceHelper.disconnect(false)
        super.onDestroy()
    }
}