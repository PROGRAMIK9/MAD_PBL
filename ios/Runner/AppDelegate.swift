import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let channelName = "offline_mesh/platform"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "OfflineMeshBridge")
    let channel = FlutterMethodChannel(name: channelName, binaryMessenger: registrar.messenger())
    let discoveryChannel = FlutterEventChannel(name: "offline_mesh/discovery", binaryMessenger: registrar.messenger())
    let bleService = BLECentralService()
    discoveryChannel.setStreamHandler(bleService)

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "snapshot":
        UIDevice.current.isBatteryMonitoringEnabled = true
        result([
          "bluetoothAvailable": true,
          "wifiDirectAvailable": false,
          "offlineMapsAvailable": true,
          "batteryLevel": Int(UIDevice.current.batteryLevel * 100),
          "platformLabel": "ios",
        ])
      case "startDiscovery":
        bleService.startDiscovery()
        result(nil)
      case "stopDiscovery":
        bleService.stopDiscovery()
        result(nil)
      case "broadcastEmergency", "shareLocationPacket":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
