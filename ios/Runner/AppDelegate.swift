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

    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "snapshot":
        result([
          "bluetoothAvailable": true,
          "wifiDirectAvailable": false,
          "offlineMapsAvailable": true,
          "platformLabel": "ios",
        ])
      case "startDiscovery", "stopDiscovery", "broadcastEmergency", "shareLocationPacket":
        result(nil)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
