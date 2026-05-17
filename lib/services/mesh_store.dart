import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/mesh_activity.dart';
import '../models/mesh_link.dart';
import '../models/mesh_location.dart';
import '../models/mesh_message.dart';
import '../models/mesh_peer.dart';
import 'platform_mesh_bridge.dart';

class MeshStore extends ChangeNotifier {
  MeshStore({PlatformMeshBridge? platformBridge}) : _platformBridge = platformBridge ?? PlatformMeshBridge() {
    unawaited(_bootstrap());
  }

  final Random _random = Random();
  final PlatformMeshBridge _platformBridge;
  StreamSubscription<MeshDiscoverySnapshot>? _discoverySubscription;

  final String localNodeId = 'node-local-01';
  final String localNodeName = 'Field Hub';
  final String passphraseHint = '32-character mesh key';

  bool meshEnabled = true;
  bool disasterMode = true;
  bool locationSharing = true;
  double batteryLevel = 0;
  double offlineSignal = 0;
  String networkLabel = 'Offline Mesh';
  String coverageLabel = 'Starting live discovery';
  String syncState = 'Waiting for Bluetooth discovery';

  final List<MeshPeer> _peers = <MeshPeer>[];
  final List<MeshMessage> _messages = <MeshMessage>[];
  final List<MeshActivity> _activities = <MeshActivity>[];
  final List<MeshLocation> _locations = <MeshLocation>[];
  final List<MeshLink> _links = <MeshLink>[];

  List<MeshPeer> get peers => List<MeshPeer>.unmodifiable(_peers);
  List<MeshMessage> get messages => List<MeshMessage>.unmodifiable(_messages);
  List<MeshActivity> get activities => List<MeshActivity>.unmodifiable(_activities);
  List<MeshLocation> get locations => List<MeshLocation>.unmodifiable(_locations);
  List<MeshLink> get links => List<MeshLink>.unmodifiable(_links);

  int get activePeers => _peers.length;

  int get relayNodes => _peers.where((MeshPeer peer) => peer.role == MeshPeerRole.relay).length;

  double get averageRelayStrength {
    if (_peers.isEmpty) {
      return 0;
    }
    final double total = _peers.fold<double>(0, (double sum, MeshPeer peer) => sum + peer.relayStrength);
    return total / _peers.length;
  }

  int get emergencyMessages =>
      _messages.where((MeshMessage message) => message.priority == MeshMessagePriority.critical).length;

  int get acknowledgedMessages => _messages.where((MeshMessage message) => message.acknowledged).length;

  Future<void> _bootstrap() async {
    final MeshPlatformSnapshot snapshot = await _platformBridge.snapshot();
    _applySnapshot(snapshot);
    if (meshEnabled) {
      await _startDiscovery();
    }
  }

  void toggleMesh() {
    meshEnabled = !meshEnabled;
    if (meshEnabled) {
      unawaited(_startDiscovery());
      syncState = 'Mesh discovery resumed';
    } else {
      unawaited(_stopDiscovery());
      syncState = 'Mesh discovery paused';
    }
    _addActivity('Mesh ${meshEnabled ? 'enabled' : 'paused'}', 'Live discovery control updated', 'control');
    notifyListeners();
  }

  void toggleDisasterMode() {
    disasterMode = !disasterMode;
    syncState = disasterMode ? 'Battery-saving emergency mode enabled' : 'Standard relay behavior restored';
    _addActivity('Disaster mode ${disasterMode ? 'enabled' : 'disabled'}', 'Energy profile switched', 'control');
    notifyListeners();
  }

  void sendText(String text) {
    final String body = text.trim();
    if (body.isEmpty) {
      return;
    }
    _appendMessage(
      MeshMessage(
        id: _newId('msg'),
        senderId: localNodeId,
        senderName: localNodeName,
        type: MeshMessageType.text,
        priority: MeshMessagePriority.normal,
        body: body,
        createdAt: DateTime.now(),
        ttl: 8,
        hops: 0,
        route: _buildRouteLabels(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'channel': 'text'},
      ),
      'Text message queued locally',
    );
  }

  void sendEmergency(String text) {
    final String content = text.trim().isEmpty ? 'Emergency alert from $localNodeName' : text.trim();
    final MeshMessage message = MeshMessage(
      id: _newId('emg'),
      senderId: localNodeId,
      senderName: localNodeName,
      type: MeshMessageType.emergency,
      priority: MeshMessagePriority.critical,
      body: content,
      createdAt: DateTime.now(),
      ttl: 18,
      hops: 0,
      route: _buildRouteLabels(),
      encrypted: true,
      acknowledged: false,
      metadata: <String, dynamic>{'priorityRouting': true, 'broadcastRepeat': 3},
    );
    _appendMessage(message, 'Emergency alert queued for broadcast');
    unawaited(_platformBridge.broadcastEmergency(message.id));
  }

  void shareLocation(String label, double latitude, double longitude) {
    _locations.insert(
      0,
      MeshLocation(
        label: label,
        latitude: latitude,
        longitude: longitude,
        kind: MeshLocationKind.safePath,
        note: 'Shared from $localNodeName',
      ),
    );

    final MeshMessage message = MeshMessage(
      id: _newId('loc'),
      senderId: localNodeId,
      senderName: localNodeName,
      type: MeshMessageType.location,
      priority: MeshMessagePriority.elevated,
      body: '$label at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
      createdAt: DateTime.now(),
      ttl: 12,
      hops: 0,
      route: _buildRouteLabels(),
      encrypted: true,
      acknowledged: false,
      metadata: <String, dynamic>{'latitude': latitude, 'longitude': longitude, 'label': label},
    );
    _appendMessage(message, 'Location packet queued locally');
    unawaited(_platformBridge.shareLocationPacket(latitude, longitude));
  }

  void injectCompressedImageRelay() {
    _appendMessage(
      MeshMessage(
        id: _newId('img'),
        senderId: localNodeId,
        senderName: localNodeName,
        type: MeshMessageType.image,
        priority: MeshMessagePriority.elevated,
        body: 'Compressed image packet ready for relay',
        createdAt: DateTime.now(),
        ttl: 10,
        hops: 0,
        route: _buildRouteLabels(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'compression': 'webp', 'sizeHintKb': 128},
      ),
      'Compressed image packet added to the queue',
    );
  }

  @override
  void dispose() {
    unawaited(_stopDiscovery());
    super.dispose();
  }

  void _applySnapshot(MeshPlatformSnapshot snapshot) {
    batteryLevel = snapshot.batteryLevel.toDouble();
    locationSharing = snapshot.offlineMapsAvailable;
    networkLabel = 'Offline Mesh • ${snapshot.platformLabel}';
    syncState = snapshot.bluetoothAvailable ? 'Bluetooth discovery ready' : 'Bluetooth unavailable on this device';
    coverageLabel = 'Searching for nearby devices';
    notifyListeners();
  }

  Future<void> _startDiscovery() async {
    try {
      await _platformBridge.startDiscovery();
      _discoverySubscription ??= _platformBridge.discoveryStream().listen(
        _ingestDiscovery,
        onError: (Object error, StackTrace stackTrace) {
          _addActivity('Discovery error', error.toString(), 'warning');
          syncState = 'Discovery error';
          notifyListeners();
        },
      );
      _addActivity('Discovery started', 'Listening for nearby devices', 'info');
      syncState = 'Scanning live nearby devices';
      notifyListeners();
    } catch (error) {
      _addActivity('Discovery unavailable', error.toString(), 'warning');
      syncState = 'Discovery unavailable';
      notifyListeners();
    }
  }

  Future<void> _stopDiscovery() async {
    await _platformBridge.stopDiscovery();
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    _peers.clear();
    _links.clear();
    coverageLabel = 'Discovery stopped';
    syncState = 'Mesh paused';
    notifyListeners();
  }

  void _ingestDiscovery(MeshDiscoverySnapshot snapshot) {
    final double signalStrength = ((snapshot.rssi + 100).clamp(0, 100)).toDouble();
    final double relayStrength = (signalStrength * 0.8).clamp(0, 100);
    final MeshPeerRole role = signalStrength >= 70 ? MeshPeerRole.relay : MeshPeerRole.receiver;
    final MeshPeer peer = MeshPeer(
      id: snapshot.deviceId,
      name: snapshot.deviceName,
      role: role,
      signalStrength: signalStrength,
      batteryLevel: 0,
      lastSeen: DateTime.now(),
      locationLabel: 'Nearby • ${snapshot.platformLabel}',
      relayStrength: relayStrength,
    );

    final bool isNewPeer = _upsertPeer(peer);
    _recalculateNetworkState();
    _refreshLinks();

    if (isNewPeer) {
      _addActivity('Device discovered', '${peer.name} • ${snapshot.rssi} dBm', 'info');
    }
    syncState = 'Live discovery from ${snapshot.platformLabel}';
    notifyListeners();
  }

  bool _upsertPeer(MeshPeer peer) {
    final int index = _peers.indexWhere((MeshPeer currentPeer) => currentPeer.id == peer.id);
    if (index == -1) {
      _peers.insert(0, peer);
      return true;
    }

    _peers[index] = peer;
    return false;
  }

  void _recalculateNetworkState() {
    if (_peers.isEmpty) {
      offlineSignal = 0;
      coverageLabel = 'No nearby devices yet';
      return;
    }

    final double totalSignal = _peers.fold<double>(0, (double sum, MeshPeer peer) => sum + peer.signalStrength);
    offlineSignal = totalSignal / _peers.length;
    coverageLabel = '${_peers.length} live nearby devices';
  }

  void _appendMessage(MeshMessage message, String activityLabel) {
    _messages.insert(0, message);
    _addActivity(activityLabel, '${message.routeLabel.isEmpty ? 'Local' : message.routeLabel} • ${message.priority.name}', message.isUrgent ? 'critical' : 'info');
    _refreshLinks();
    notifyListeners();
  }

  void _addActivity(String title, String subtitle, String level) {
    _activities.insert(
      0,
      MeshActivity(title: title, subtitle: subtitle, timestamp: DateTime.now(), level: level),
    );
    if (_activities.length > 10) {
      _activities.removeLast();
    }
  }

  void _refreshLinks() {
    final List<String> route = _buildRouteLabels();
    _links
      ..clear()
      ..addAll(route.asMap().entries.map((MapEntry<int, String> entry) {
        final String fromId = entry.key == 0 ? localNodeId : route[entry.key - 1];
        final String toId = route[entry.key];
        final MeshPeer? peer = _peers.cast<MeshPeer?>().firstWhere(
          (MeshPeer? currentPeer) => currentPeer?.id == toId,
          orElse: () => null,
        );
        return MeshLink(
          fromId: fromId,
          toId: toId,
          strength: peer?.presenceScore ?? 50,
          active: true,
          label: entry.key == 0 ? 'local uplink' : 'relay hop ${entry.key}',
        );
      }));
  }

  List<String> _buildRouteLabels() {
    final List<MeshPeer> sortedPeers = List<MeshPeer>.of(_peers)
      ..sort((MeshPeer left, MeshPeer right) => right.presenceScore.compareTo(left.presenceScore));
    return sortedPeers.take(3).map((MeshPeer peer) => peer.name).toList(growable: false);
  }

  String _newId(String prefix) {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final int nonce = _random.nextInt(9000) + 1000;
    return '$prefix-$millis-$nonce';
  }
}
