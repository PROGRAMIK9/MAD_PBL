import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MeshPlatformSnapshot {
  const MeshPlatformSnapshot({
    required this.bluetoothAvailable,
    required this.wifiDirectAvailable,
    required this.offlineMapsAvailable,
    required this.platformLabel,
  });

  final bool bluetoothAvailable;
  final bool wifiDirectAvailable;
  final bool offlineMapsAvailable;
  final String platformLabel;
}

class PlatformMeshBridge {
  PlatformMeshBridge({MethodChannel? channel}) : _channel = channel ?? const MethodChannel('offline_mesh/platform');

  final MethodChannel _channel;

  Future<MeshPlatformSnapshot> snapshot() async {
    if (kIsWeb) {
      return const MeshPlatformSnapshot(
        bluetoothAvailable: false,
        wifiDirectAvailable: false,
        offlineMapsAvailable: false,
        platformLabel: 'web-simulated',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel.invokeMapMethod<Object?, Object?>('snapshot');
      return MeshPlatformSnapshot(
        bluetoothAvailable: result?['bluetoothAvailable'] as bool? ?? false,
        wifiDirectAvailable: result?['wifiDirectAvailable'] as bool? ?? false,
        offlineMapsAvailable: result?['offlineMapsAvailable'] as bool? ?? false,
        platformLabel: result?['platformLabel'] as String? ?? defaultTargetPlatform.name,
      );
    } on MissingPluginException {
      return MeshPlatformSnapshot(
        bluetoothAvailable: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
        wifiDirectAvailable: defaultTargetPlatform == TargetPlatform.android,
        offlineMapsAvailable: true,
        platformLabel: defaultTargetPlatform.name,
      );
    }
  }

  Future<void> startDiscovery() async {
    try {
      await _channel.invokeMethod<void>('startDiscovery');
    } on MissingPluginException {
      return;
    }
  }

  Future<void> stopDiscovery() async {
    try {
      await _channel.invokeMethod<void>('stopDiscovery');
    } on MissingPluginException {
      return;
    }
  }

  Future<void> broadcastEmergency(String messageId) async {
    try {
      await _channel.invokeMethod<void>('broadcastEmergency', <String, Object?>{'messageId': messageId});
    } on MissingPluginException {
      return;
    }
  }

  Future<void> shareLocationPacket(double latitude, double longitude) async {
    try {
      await _channel.invokeMethod<void>('shareLocationPacket', <String, Object?>{
        'latitude': latitude,
        'longitude': longitude,
      });
    } on MissingPluginException {
      return;
    }
  }
}
