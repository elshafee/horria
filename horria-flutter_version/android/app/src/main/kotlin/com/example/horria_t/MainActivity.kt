package com.example.horria_t

import android.Manifest
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
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import com.jeremyliao.liveeventbus.LiveEventBus
import com.lepu.blepro.constants.Ble
import com.lepu.blepro.event.EventMsgConst
import com.lepu.blepro.event.InterfaceEvent
import com.lepu.blepro.ext.BleServiceHelper
import com.lepu.blepro.ext.pc303.BpMode
import com.lepu.blepro.ext.pc303.BpResult
import com.lepu.blepro.ext.pc303.BpResultError
import com.lepu.blepro.ext.pc303.DeviceInfo
import com.lepu.blepro.ext.pc303.EcgResult
import com.lepu.blepro.ext.pc303.GluResult
import com.lepu.blepro.ext.pc303.RtEcgWave
import com.lepu.blepro.ext.pc303.RtOxyParam
import com.lepu.blepro.ext.pc303.TempMode
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
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BATTERY_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getBatteryLevel") {
                val batteryLevel = getBatteryLevel()
                if (batteryLevel != -1) result.success(batteryLevel)
                else result.error("UNAVAILABLE", "Battery level not available.", null)
            } else {
                result.notImplemented()
            }
        }

        // 2. LEPU Device Controller Method Channel
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LEPU_COMMAND_CHANNEL
        ).setMethodCallHandler { call, result ->
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
        EventChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            LEPU_STREAM_CHANNEL
        ).setStreamHandler(
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
            val bluetooth =
                Bluetooth(Bluetooth.MODEL_CMI_PC303, device.name ?: "PC303", device, -70, null)

            sendToFlutter("status", "Connecting to $mac...")

            BleServiceHelper.BleServiceHelper.setInterfaces(Bluetooth.MODEL_CMI_PC303)
            lifecycle.addObserver(BIOL(this, intArrayOf(Bluetooth.MODEL_CMI_PC303)))
            BleServiceHelper.BleServiceHelper.stopScan()
            BleServiceHelper.BleServiceHelper.connect(
                applicationContext,
                Bluetooth.MODEL_CMI_PC303,
                device,
                bluetooth = bluetooth
            )

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
            val intent = ContextWrapper(applicationContext).registerReceiver(
                null,
                IntentFilter(Intent.ACTION_BATTERY_CHANGED)
            )
            batteryLevel =
                intent!!.getIntExtra(BatteryManager.EXTRA_LEVEL, -1) * 100 / intent.getIntExtra(
                    BatteryManager.EXTRA_SCALE,
                    -1
                )
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
                Manifest.permission.ACCESS_COARSE_LOCATION,
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.BLUETOOTH,
                Manifest.permission.BLUETOOTH_ADMIN
            )
        }

        PermissionX.init(this)
            .permissions(*permissions)
            .onExplainRequestReason { scope, deniedList ->
                scope.showRequestReasonDialog(
                    deniedList,
                    "Bluetooth and Location permissions are required to interface with medical kits",
                    "OK",
                    "Cancel"
                )
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
                if (ActivityCompat.checkSelfPermission(
                        this,
                        Manifest.permission.BLUETOOTH_CONNECT
                    ) == PackageManager.PERMISSION_GRANTED
                ) {
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
        } catch (ex: Exception) {
            ex.printStackTrace()
        }

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

        // --- Live Telemetry Observers Pipe Directly to Flutter Event Sink ---
        // ---                      Device Info Data Pipeline               ---

//        Device Found & Connecting
        LiveEventBus.get<Bluetooth>(EventMsgConst.Discovery.EventDeviceFound)
            .observe(this) {
                if (!isAutoConnecting) {
                    isAutoConnecting = true
                    sendToFlutter("status", "Device Found: ${it.name}")
                    sendToFlutter("status", "Connecting....")
                    BleServiceHelper.BleServiceHelper.setInterfaces(it.model)
                    lifecycle.addObserver(BIOL(this, intArrayOf(it.model)))
                    BleServiceHelper.BleServiceHelper.stopScan()
                    BleServiceHelper.BleServiceHelper.connect(
                        applicationContext,
                        it.model,
                        it.device,
                        bluetooth = it
                    )
                    connectedModel = it.model
                    BluetoothController.clear()
                }
            }

//        Device Disconnected
        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceDisconnectReason)
            .observe(this) {
                isAutoConnecting = false
                sendToFlutter("status", "Disconnected (reason: $it)")
                startScanning()
            }

//        Device Ready
        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceReady)
            .observe(this) {
                sendToFlutter("status", "Connected")
                BleServiceHelper.BleServiceHelper.pc300GetInfo(connectedModel)
            }

//        Device Battery state
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300DeviceInfo)
            .observe(this) {
                val data = it.data as DeviceInfo
                val batStatus = when (data.batStatus) {
                    0 -> "Normal"
                    1 -> "Charging"
                    2 -> "Full"
                    else -> "Unknown"
                }
                sendToFlutter("battery_level", (data.batLevel) / 3)
                sendToFlutter("battery_state", batStatus)
            }

        // --- Error and Hardware State Observers ---

        LiveEventBus.get<Int>(EventMsgConst.Ble.EventBleDeviceDisconnectReason)
            .observe(this) {
                isAutoConnecting = false
                val reason = when (it) {
                    0 -> "Normal Disconnect"
                    else -> "Error Code: $it"
                }
                sendToFlutter("status", "Disconnected ($reason)")
                startScanning()
            }

//        ******************************************************************************************

        // ---                      Sensor Data Pipeline                       ---

/////////////////////////////////////////////////////////////////////////////////////////////////////
        // >>>>>>>>>>               ECG Data                <<<<<<<<<<
        /*
        - ecgMode   ->  returns the current mode if it Started/ Stop
        - ecgWave ->    returns the real data contains floats, is probeOff, samplingRate
        - ecgResult ->  returns the final results
        */

//      ECG Started
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300EcgStart)
            .observe(this) {
                sendToFlutter("ecgMode", "STARTED")
            }
//      ECG Stopped
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300EcgStop)
            .observe(this) {
                sendToFlutter("ecgMode", "STOPPED")
            }

//        ECG Wave
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

//      ECG Result
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300EcgResult)
            .observe(this) {
                try {
                    val data = it.data
                    if (data is EcgResult) {
                        val ecgDataMap = mapOf("hr" to data.hr, "result" to data.result, "resultMess" to data.resultMess)
                        sendToFlutter("ecgResult", ecgDataMap)
                    } else if (data is Array<*>) {
                        if (data.isNotEmpty() && data[0] is EcgResult) {
                            val first = data[0] as EcgResult
                            val ecgDataMap = mapOf("hr" to first.hr, "result" to first.result, "resultMess" to first.resultMess)
                            sendToFlutter("ecgResult", ecgDataMap)
                        } else {
                            sendToFlutter("status", "ecgResult data empty or unknown array")
                        }
                    } else if (data is List<*>) {
                        if (data.isNotEmpty() && data[0] is EcgResult) {
                            val first = data[0] as EcgResult
                            val ecgDataMap = mapOf("hr" to first.hr, "result" to first.result, "resultMess" to first.resultMess)
                            sendToFlutter("ecgResult", ecgDataMap)
                        }
                    } else {
                        sendToFlutter("status", "ecgResult unknown format")
                    }
                } catch (e: Exception) {
                    sendToFlutter("status", "ecgResult err: ${e.message}")
                }
            }


/////////////////////////////////////////////////////////////////////////////////////////////////////
        // >>>>>>>>>>               Oximeter Data                <<<<<<<<<<

//        prob off

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

/////////////////////////////////////////////////////////////////////////////////////////////////////
        // >>>>>>>>>>               Glucose Data              <<<<<<<<<<
        /*
        - result   -> resultReceived
        - resultReceived ->  resultReceived
        */

        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300GluResult)
            .observe(this) {
                val data = it.data as GluResult
                val unit = if (data.unit == 0) "mmol/L" else "mg/dL"
                sendToFlutter("result", data.resultMess)
                sendToFlutter("resultReceived", data.data)
            }
/////////////////////////////////////////////////////////////////////////////////////////////////////
        // >>>>>>>>>>               Temperature Data              <<<<<<<<<<
        /*
        - bpMode   -> Current Blood Pressure Mode Started / Stopped
        - RtBpData -> Real Time Data While Measuring
        - bpResult -> Final Blood Pressure Result ( sys, dia, pr) / Result Error
        */

//        Current Temp System mode
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300GetTempMode)
            .observe(this) {
                val data = it.data as TempMode
                sendToFlutter("tempMode", data)
            }

//        Final Temperature Result
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300TempResult)
            .observe(this) {
                val data = it.data as Float
                val status = if (data !in 32.0..43.0) "ABNORMAL" else "NORMAL"
                sendToFlutter("tempResult", data)
                sendToFlutter("tempStatus", status)
            }

/////////////////////////////////////////////////////////////////////////////////////////////////////
        // >>>>>>>>>>               Blood Pressure Data           <<<<<<<<<<

        /*
        - bpMode   -> Current Blood Pressure Mode Started / Stopped
        - RtBpData -> Real Time Data While Measuring
        - bpResult -> Final Blood Pressure Result ( sys, dia, pr) / Result Error
         */

//        Current Blood Pressure Mode
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpMode)
            .observe(this) {
                val data = it.data as BpMode
                sendToFlutter("bpMode", data)
            }

//        Blood Pressure Measurement Started
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpStart)
            .observe(this) {
                sendToFlutter("bpMode", "STARTED")
            }

//        Blood Pressure Measurement Stopped
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpStop)
            .observe(this) {
                sendToFlutter("bpMode", "STOPPED")
            }

//        Blood Pressure Measurement Live Data
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300RtBpData)
            .observe(this) {
                val data = it.data as Int
                sendToFlutter("RtBpData", data)
            }

//        Final Blood Pressure Result
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpResult)
            .observe(this) {
                val data = it.data as BpResult
                val bpData = mutableMapOf(
                    "sys" to data.sys,
                    "dia" to data.dia,
                    "pr" to data.pr,
                    "map" to data.map
                )
                sendToFlutter("bpResult", bpData)
            }

//        Blood Pressure Error Result
        LiveEventBus.get<InterfaceEvent>(InterfaceEvent.PC300.EventPc300BpErrorResult)
            .observe(this) {
                val data = it.data as BpResultError
                sendToFlutter("bpResult", data)
            }

/////////////////////////////////////////////////////////////////////////////////////////////////////

    }

    override fun onBleStateChanged(model: Int, state: Int) {
        sendToFlutter("bleState", state == Ble.State.CONNECTED)
    }

    override fun onDestroy() {
        BleServiceHelper.BleServiceHelper.disconnect(false)
        super.onDestroy()
    }
}