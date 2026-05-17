import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/mesh_activity.dart';
import '../models/mesh_link.dart';
import '../models/mesh_location.dart';
import '../models/mesh_message.dart';
import '../models/mesh_peer.dart';

class MeshStore extends ChangeNotifier {
  MeshStore() {
    _seed();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _tick());
  }

  final Random _random = Random();
  final String localNodeId = 'node-local-01';
  final String localNodeName = 'Field Hub';
  final String passphraseHint = '32-character mesh key';

  late final Timer _timer;

  bool meshEnabled = true;
  bool disasterMode = true;
  bool locationSharing = true;
  double batteryLevel = 78;
  double offlineSignal = 91;
  String networkLabel = 'Rescue Mesh';
  String coverageLabel = '12 nearby nodes';
  String syncState = 'Relaying packets locally';

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

  int get activePeers => _peers.where((MeshPeer peer) => peer.signalStrength > 30).length;

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

  void toggleMesh() {
    meshEnabled = !meshEnabled;
    syncState = meshEnabled ? 'Mesh resumed across nearby devices' : 'Mesh paused locally';
    _addActivity('Mesh ${meshEnabled ? 'enabled' : 'paused'}', 'Network control updated from the dashboard', 'control');
    notifyListeners();
  }

  void toggleDisasterMode() {
    disasterMode = !disasterMode;
    syncState = disasterMode ? 'Battery-saving emergency mode enabled' : 'Standard relay behavior restored';
    _addActivity('Disaster mode ${disasterMode ? 'enabled' : 'disabled'}', 'Energy profile switched', 'control');
    notifyListeners();
  }

  void sendText(String text) {
    if (text.trim().isEmpty) {
      return;
    }
    _appendMessage(
      MeshMessage(
        id: _newId('msg'),
        senderId: localNodeId,
        senderName: localNodeName,
        type: MeshMessageType.text,
        priority: MeshMessagePriority.normal,
        body: text.trim(),
        createdAt: DateTime.now(),
        ttl: 8,
        hops: 0,
        route: _buildRoute(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'channel': 'text'},
      ),
      'Text message queued for local relays',
    );
  }

  void sendEmergency(String text) {
    final String content = text.trim().isEmpty ? 'Emergency alert from $localNodeName' : text.trim();
    _appendMessage(
      MeshMessage(
        id: _newId('emg'),
        senderId: localNodeId,
        senderName: localNodeName,
        type: MeshMessageType.emergency,
        priority: MeshMessagePriority.critical,
        body: content,
        createdAt: DateTime.now(),
        ttl: 18,
        hops: 0,
        route: _buildEmergencyRoute(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'priorityRouting': true, 'broadcastRepeat': 3},
      ),
      'Emergency broadcast pushed to nearby relays',
    );
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

    _appendMessage(
      MeshMessage(
        id: _newId('loc'),
        senderId: localNodeId,
        senderName: localNodeName,
        type: MeshMessageType.location,
        priority: MeshMessagePriority.elevated,
        body: '$label at ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)}',
        createdAt: DateTime.now(),
        ttl: 12,
        hops: 0,
        route: _buildRoute(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'latitude': latitude, 'longitude': longitude, 'label': label},
      ),
      'Location marker relayed offline',
    );
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
        route: _buildRoute(),
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'compression': 'webp', 'sizeHintKb': 128},
      ),
      'Compressed image packet added to the queue',
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _seed() {
    _peers.addAll(<MeshPeer>[
      MeshPeer.sample(
        id: 'node-01',
        name: 'Riya',
        role: MeshPeerRole.relay,
        locationLabel: 'Gate 3',
        signalStrength: 90,
        batteryLevel: 62,
        relayStrength: 84,
      ),
      MeshPeer.sample(
        id: 'node-02',
        name: 'Sam',
        role: MeshPeerRole.sender,
        locationLabel: 'Medical Tent',
        signalStrength: 72,
        batteryLevel: 54,
        relayStrength: 60,
      ),
      MeshPeer.sample(
        id: 'node-03',
        name: 'Asha',
        role: MeshPeerRole.receiver,
        locationLabel: 'West Exit',
        signalStrength: 85,
        batteryLevel: 71,
        relayStrength: 75,
      ),
      MeshPeer.sample(
        id: 'node-04',
        name: 'Omar',
        role: MeshPeerRole.relay,
        locationLabel: 'Tower A',
        signalStrength: 68,
        batteryLevel: 47,
        relayStrength: 88,
      ),
      MeshPeer.sample(
        id: 'node-05',
        name: 'Mina',
        role: MeshPeerRole.receiver,
        locationLabel: 'Shelter 2',
        signalStrength: 58,
        batteryLevel: 79,
        relayStrength: 49,
      ),
    ]);

    _messages.addAll(<MeshMessage>[
      MeshMessage(
        id: _newId('msg'),
        senderId: 'node-03',
        senderName: 'Asha',
        type: MeshMessageType.text,
        priority: MeshMessagePriority.normal,
        body: 'Staying near the west exit until the route opens.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 4)),
        ttl: 7,
        hops: 2,
        route: <String>['Asha', 'Omar', 'Field Hub'],
        encrypted: true,
        acknowledged: true,
        metadata: <String, dynamic>{'channel': 'chat'},
      ),
      MeshMessage(
        id: _newId('emg'),
        senderId: 'node-02',
        senderName: 'Sam',
        type: MeshMessageType.emergency,
        priority: MeshMessagePriority.critical,
        body: 'Possible blockage near Gate 3. Need clear relay path.',
        createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
        ttl: 15,
        hops: 3,
        route: <String>['Sam', 'Riya', 'Omar', 'Field Hub'],
        encrypted: true,
        acknowledged: false,
        metadata: <String, dynamic>{'priorityRouting': true},
      ),
    ]);

    _activities.addAll(<MeshActivity>[
      MeshActivity(
        title: 'Relay path stabilized',
        subtitle: 'Asha -> Omar -> Field Hub',
        timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        level: 'info',
      ),
      MeshActivity(
        title: 'Emergency packet broadcast',
        subtitle: 'Gate 3 alert repeated across local relays',
        timestamp: DateTime.now().subtract(const Duration(minutes: 3)),
        level: 'critical',
      ),
      MeshActivity(
        title: 'Battery saver engaged',
        subtitle: 'Bluetooth LE scan interval increased',
        timestamp: DateTime.now().subtract(const Duration(minutes: 7)),
        level: 'warning',
      ),
    ]);

    _locations.addAll(<MeshLocation>[
      const MeshLocation(
        label: 'Safe Route A',
        latitude: 40.7121,
        longitude: -74.0042,
        kind: MeshLocationKind.safePath,
        note: 'Low congestion, marked by volunteers',
      ),
      const MeshLocation(
        label: 'Gate 3 Hazard',
        latitude: 40.7138,
        longitude: -74.0064,
        kind: MeshLocationKind.dangerZone,
        note: 'Debris reported, avoid east lane',
      ),
      const MeshLocation(
        label: 'Rescue Checkpoint',
        latitude: 40.7145,
        longitude: -74.0031,
        kind: MeshLocationKind.rescuePoint,
        note: 'Ambulance handoff point',
      ),
    ]);

    _refreshLinks();
  }

  void _appendMessage(MeshMessage message, String activityLabel) {
    _messages.insert(0, message);
    _addActivity(activityLabel, '${message.routeLabel} • ${message.priority.name}', message.isUrgent ? 'critical' : 'info');
    _refreshLinks();
    notifyListeners();
  }

  void _addActivity(String title, String subtitle, String level) {
    _activities.insert(
      0,
      MeshActivity(title: title, subtitle: subtitle, timestamp: DateTime.now(), level: level),
    );
    if (_activities.length > 8) {
      _activities.removeLast();
    }
  }

  void _refreshLinks() {
    _links
      ..clear()
      ..addAll(_buildRoute().asMap().entries.map((MapEntry<int, String> entry) {
        final List<String> route = _buildRoute();
        final String fromId = entry.key == 0 ? localNodeId : route[entry.key - 1];
        final String toId = route[entry.key];
        final MeshPeer? peer = _peers.cast<MeshPeer?>().firstWhere(
          (MeshPeer? currentPeer) => currentPeer?.id == toId,
          orElse: () => null,
        );
        return MeshLink(
          fromId: fromId,
          toId: toId,
          strength: peer?.presenceScore ?? 65,
          active: true,
          label: entry.key == 0 ? 'local uplink' : 'relay hop ${entry.key}',
        );
      }));
  }

  List<String> _buildRoute() {
    final List<MeshPeer> sortedPeers = List<MeshPeer>.of(_peers)
      ..sort((MeshPeer left, MeshPeer right) => right.presenceScore.compareTo(left.presenceScore));
    return sortedPeers.take(3).map((MeshPeer peer) => peer.id).toList(growable: false);
  }

  List<String> _buildEmergencyRoute() {
    final List<String> route = _buildRoute();
    if (route.length < 3) {
      return route;
    }
    return <String>[route[0], route[1], route[2], route[0]];
  }

  void _tick() {
    if (!meshEnabled) {
      notifyListeners();
      return;
    }

    for (int index = 0; index < _peers.length; index += 1) {
      _peers[index] = _peers[index].jittered(_random);
    }

    batteryLevel = (batteryLevel - (disasterMode ? 0.3 : 0.6)).clamp(8, 100);
    offlineSignal = (offlineSignal + (_random.nextDouble() * 8 - 4)).clamp(48, 100);
    coverageLabel = '${activePeers + 7} nearby nodes';
    syncState = disasterMode
        ? 'Energy-optimized relays active across the mesh'
        : 'Standard sync interval with neighbor discovery';

    for (int index = _messages.length - 1; index >= 0; index -= 1) {
      final MeshMessage current = _messages[index];
      final int nextTtl = current.ttl - 1;
      if (nextTtl <= 0) {
        _messages.removeAt(index);
        continue;
      }

      if (!current.acknowledged && DateTime.now().difference(current.createdAt).inSeconds > 6) {
        _messages[index] = current.copyWith(
          ttl: nextTtl,
          hops: current.hops + 1,
          acknowledged: current.priority == MeshMessagePriority.critical ? true : current.acknowledged,
          route: current.route,
        );
      } else {
        _messages[index] = current.copyWith(ttl: nextTtl, hops: current.hops + 1, route: current.route);
      }
    }

    if (_random.nextBool()) {
      _activities.insert(
        0,
        MeshActivity(
          title: 'Neighbor heartbeat updated',
          subtitle: 'Signal paths refreshed without internet',
          timestamp: DateTime.now(),
          level: 'info',
        ),
      );
      if (_activities.length > 8) {
        _activities.removeLast();
      }
    }

    _refreshLinks();
    notifyListeners();
  }

  String _newId(String prefix) {
    final int millis = DateTime.now().millisecondsSinceEpoch;
    final int nonce = _random.nextInt(9000) + 1000;
    return '$prefix-$millis-$nonce';
  }
}