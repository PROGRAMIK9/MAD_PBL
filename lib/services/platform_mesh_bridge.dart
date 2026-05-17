import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MeshPlatformSnapshot {
  const MeshPlatformSnapshot({
    required this.bluetoothAvailable,
    required this.wifiDirectAvailable,
    required this.offlineMapsAvailable,
    required this.batteryLevel,
    required this.platformLabel,
  });

  final bool bluetoothAvailable;
  final bool wifiDirectAvailable;
  final bool offlineMapsAvailable;
  final int batteryLevel;
  final String platformLabel;
}

class MeshDiscoverySnapshot {
  const MeshDiscoverySnapshot({
    required this.deviceId,
    required this.deviceName,
    required this.rssi,
    required this.platformLabel,
  });

  factory MeshDiscoverySnapshot.fromMap(Map<Object?, Object?> map) {
    return MeshDiscoverySnapshot(
      deviceId: map['deviceId'] as String? ?? 'unknown-device',
      deviceName: map['deviceName'] as String? ?? 'Nearby device',
      rssi: (map['rssi'] as num?)?.toInt() ?? -70,
      platformLabel: map['platformLabel'] as String? ?? defaultTargetPlatform.name,
    );
  }

  final String deviceId;
  final String deviceName;
  final int rssi;
  final String platformLabel;
}

class PlatformMeshBridge {
  PlatformMeshBridge({MethodChannel? channel, EventChannel? discoveryChannel})
      : _channel = channel ?? const MethodChannel('offline_mesh/platform'),
        _discoveryChannel = discoveryChannel ?? const EventChannel('offline_mesh/discovery');

  final MethodChannel _channel;
  final EventChannel _discoveryChannel;

  Future<MeshPlatformSnapshot> snapshot() async {
    if (kIsWeb) {
      return const MeshPlatformSnapshot(
        bluetoothAvailable: false,
        wifiDirectAvailable: false,
        offlineMapsAvailable: false,
        batteryLevel: 0,
        platformLabel: 'web-simulated',
      );
    }

    try {
      final Map<Object?, Object?>? result = await _channel.invokeMapMethod<Object?, Object?>('snapshot');
      return MeshPlatformSnapshot(
        bluetoothAvailable: result?['bluetoothAvailable'] as bool? ?? false,
        wifiDirectAvailable: result?['wifiDirectAvailable'] as bool? ?? false,
        offlineMapsAvailable: result?['offlineMapsAvailable'] as bool? ?? false,
        batteryLevel: (result?['batteryLevel'] as num?)?.round() ?? 0,
        platformLabel: result?['platformLabel'] as String? ?? defaultTargetPlatform.name,
      );
    } on MissingPluginException {
      return MeshPlatformSnapshot(
        bluetoothAvailable: defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS,
        wifiDirectAvailable: defaultTargetPlatform == TargetPlatform.android,
        offlineMapsAvailable: true,
        batteryLevel: 0,
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

  Stream<MeshDiscoverySnapshot> discoveryStream() {
    if (kIsWeb) {
      return const Stream<MeshDiscoverySnapshot>.empty();
    }

    return _discoveryChannel.receiveBroadcastStream().map((Object? event) {
      final Map<Object?, Object?> map = event as Map<Object?, Object?>;
      return MeshDiscoverySnapshot.fromMap(map);
    });
  }
}
