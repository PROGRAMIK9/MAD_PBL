import 'package:flutter/services.dart';

class IosBleBridge {
  static const MethodChannel _channel = MethodChannel('offline_mesh/platform');

  Future<void> startDiscovery() async {
    await _channel.invokeMethod('startDiscovery');
  }

  Future<void> stopDiscovery() async {
    await _channel.invokeMethod('stopDiscovery');
  }
}
