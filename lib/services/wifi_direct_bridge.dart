import 'package:flutter/services.dart';

class WifiDirectBridge {
  static const MethodChannel _channel = MethodChannel('offline_mesh/platform');

  Future<void> startDiscovery() async {
    await _channel.invokeMethod('startWifiDirectDiscovery');
  }

  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopWifiDirectDiscovery');
  }
}
