import 'package:flutter/services.dart';

class WifiDirectBridge {
  static const MethodChannel _channel = MethodChannel('offline_mesh/platform');

  Future<void> startDiscovery() async {
    await _channel.invokeMethod('startDiscovery');
  }

  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }

  Future<void> setSymmetricKey(String base64Key) async {
    await _channel.invokeMethod('setSymmetricKey', base64Key);
  }

  Future<void> sendMessage(String address, String payload) async {
    await _channel.invokeMethod('wifidirectSend', {'address': address, 'payload': payload});
  }
}
