package com.example.offline_mesh_app

import android.Manifest
import android.annotation.SuppressLint
import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothManager
import android.bluetooth.le.ScanCallback
import android.bluetooth.le.ScanResult
import android.bluetooth.le.ScanSettings
import android.content.Context
import android.content.pm.PackageManager
import android.os.BatteryManager
import android.os.Build
import androidx.core.app.ActivityCompat
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
  private val methodChannelName = "offline_mesh/platform"
  private val discoveryChannelName = "offline_mesh/discovery"
  private val permissionRequestCode = 4401

  private var pendingDiscoveryStart = false
  private var discoverySink: EventChannel.EventSink? = null
  private var bluetoothScannerController: BluetoothScannerController? = null
  private var wifiDirectService: WifiDirectService? = null

  override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
    super.configureFlutterEngine(flutterEngine)

    val controller = BluetoothScannerController(this)
    bluetoothScannerController = controller
    wifiDirectService = WifiDirectService(this)

    MethodChannel(flutterEngine.dartExecutor.binaryMessenger, methodChannelName).setMethodCallHandler { call, result ->
      handleMethodCall(call, result, controller)
    }

    EventChannel(flutterEngine.dartExecutor.binaryMessenger, discoveryChannelName).setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        discoverySink = events
        controller.attachSink(events)
        wifiDirectService?.attachSink(events)
      }

      override fun onCancel(arguments: Any?) {
        discoverySink = null
        controller.attachSink(null)
        controller.stopScanning()
        wifiDirectService?.stopDiscovery()
      }
    })
  }

  override fun onDestroy() {
    bluetoothScannerController?.stopScanning()
    bluetoothScannerController = null
    super.onDestroy()
  }

  override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
    super.onRequestPermissionsResult(requestCode, permissions, grantResults)
    if (requestCode == permissionRequestCode && pendingDiscoveryStart) {
      if (grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
        bluetoothScannerController?.startScanning()
      } else {
        discoverySink?.error("permissions_denied", "Bluetooth permissions are required for discovery.", null)
      }
      pendingDiscoveryStart = false
    }
  }

  private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result, controller: BluetoothScannerController) {
    when (call.method) {
      "snapshot" -> result.success(buildSnapshot())
      "startDiscovery" -> {
        if (ensurePermissions()) {
          controller.startScanning()
          wifiDirectService?.startDiscovery()
          result.success(null)
        } else {
          pendingDiscoveryStart = true
          requestBluetoothPermissions()
          result.error("permissions_missing", "Bluetooth permissions requested.", null)
        }
      }
      "stopDiscovery" -> {
        controller.stopScanning()
        wifiDirectService?.stopDiscovery()
        result.success(null)
      }
      "broadcastEmergency" -> result.success(null)
      "wifidirectConnect" -> {
        val addr = call.arguments as? String
        if (addr != null) {
          wifiDirectService?.connectToDevice(addr)
          result.success(null)
        } else {
          result.error("invalid_args", "Expected device address", null)
        }
      }
      "wifidirectSend" -> {
        val args = call.arguments as? Map<*, *>
        val addr = args?.get("address") as? String
        val payload = args?.get("payload") as? String
        if (addr != null && payload != null) {
          wifiDirectService?.sendMessageTo(addr, 8988, payload)
          result.success(null)
        } else {
          result.error("invalid_args", "Expected address and payload", null)
        }
      }
      "shareLocationPacket" -> result.success(null)
      else -> result.notImplemented()
    }
  }

  private fun buildSnapshot(): Map<String, Any> {
    val bluetoothManager = getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    val adapter = bluetoothManager.adapter
    val batteryLevel = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
      val batteryManager = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
      batteryManager.getIntProperty(BatteryManager.BATTERY_PROPERTY_CAPACITY)
    } else {
      0
    }

    return mapOf(
      "bluetoothAvailable" to (adapter != null && adapter.isEnabled),
      "wifiDirectAvailable" to packageManager.hasSystemFeature(PackageManager.FEATURE_WIFI_DIRECT),
      "offlineMapsAvailable" to true,
      "batteryLevel" to batteryLevel,
      "platformLabel" to "android-${Build.VERSION.SDK_INT}"
    )
  }

  private fun ensurePermissions(): Boolean {
    val requiredPermissions = permissionsNeeded()
    return requiredPermissions.all { permission ->
      ActivityCompat.checkSelfPermission(this, permission) == PackageManager.PERMISSION_GRANTED
    }
  }

  private fun permissionsNeeded(): Array<String> {
    return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
      arrayOf(Manifest.permission.BLUETOOTH_SCAN, Manifest.permission.BLUETOOTH_CONNECT)
    } else {
      arrayOf(Manifest.permission.ACCESS_FINE_LOCATION)
    }
  }

  private fun requestBluetoothPermissions() {
    ActivityCompat.requestPermissions(this, permissionsNeeded(), permissionRequestCode)
  }
}

private class BluetoothScannerController(private val context: Context) {
  private val bluetoothAdapter: BluetoothAdapter? by lazy {
    val manager = context.getSystemService(Context.BLUETOOTH_SERVICE) as BluetoothManager
    manager.adapter
  }

  private var scanCallback: ScanCallback? = null
  private var eventSink: EventChannel.EventSink? = null
  private val seenDevices = mutableMapOf<String, Long>()

  fun attachSink(sink: EventChannel.EventSink?) {
    eventSink = sink
  }

  @SuppressLint("MissingPermission")
  fun startScanning() {
    val adapter = bluetoothAdapter ?: run {
      eventSink?.error("bluetooth_unavailable", "Bluetooth adapter is unavailable.", null)
      return
    }

    if (!adapter.isEnabled) {
      eventSink?.error("bluetooth_disabled", "Bluetooth is disabled on this device.", null)
      return
    }

    val scanner = adapter.bluetoothLeScanner ?: run {
      eventSink?.error("scanner_unavailable", "Bluetooth LE scanner is unavailable.", null)
      return
    }

    if (scanCallback != null) {
      return
    }

    seenDevices.clear()
    scanCallback = object : ScanCallback() {
      override fun onScanResult(callbackType: Int, result: ScanResult) {
        emit(result)
      }

      override fun onBatchScanResults(results: MutableList<ScanResult>) {
        results.forEach { emit(it) }
      }

      override fun onScanFailed(errorCode: Int) {
        eventSink?.error("scan_failed", "Bluetooth scan failed with code $errorCode.", null)
      }
    }

    val settings = ScanSettings.Builder()
      .setScanMode(ScanSettings.SCAN_MODE_LOW_LATENCY)
      .build()

    scanner.startScan(null, settings, scanCallback)
    eventSink?.success(mapOf("type" to "status", "message" to "scan_started"))
  }

  @SuppressLint("MissingPermission")
  fun stopScanning() {
    val adapter = bluetoothAdapter ?: return
    val scanner = adapter.bluetoothLeScanner ?: return
    scanCallback?.let { scanner.stopScan(it) }
    scanCallback = null
    eventSink?.success(mapOf("type" to "status", "message" to "scan_stopped"))
  }

  private fun emit(result: ScanResult) {
    val device = result.device
    val address = device.address ?: return
    val now = System.currentTimeMillis()
    val lastSeen = seenDevices[address]
    if (lastSeen != null && now - lastSeen < 1200L) {
      return
    }
    seenDevices[address] = now

    val deviceName = device.name?.takeIf { it.isNotBlank() } ?: address.takeLast(8)
    eventSink?.success(
      mapOf(
        "deviceId" to address,
        "deviceName" to deviceName,
        "rssi" to result.rssi,
        "platformLabel" to "android"
      )
    )
  }
}
