import 'dart:math';

enum MeshPeerRole { sender, receiver, relay }

class MeshPeer {
  const MeshPeer({
    required this.id,
    required this.name,
    required this.role,
    required this.signalStrength,
    required this.batteryLevel,
    required this.lastSeen,
    required this.locationLabel,
    required this.relayStrength,
  });

  final String id;
  final String name;
  final MeshPeerRole role;
  final double signalStrength;
  final double batteryLevel;
  final DateTime lastSeen;
  final String locationLabel;
  final double relayStrength;

  MeshPeer copyWith({
    String? id,
    String? name,
    MeshPeerRole? role,
    double? signalStrength,
    double? batteryLevel,
    DateTime? lastSeen,
    String? locationLabel,
    double? relayStrength,
  }) {
    return MeshPeer(
      id: id ?? this.id,
      name: name ?? this.name,
      role: role ?? this.role,
      signalStrength: signalStrength ?? this.signalStrength,
      batteryLevel: batteryLevel ?? this.batteryLevel,
      lastSeen: lastSeen ?? this.lastSeen,
      locationLabel: locationLabel ?? this.locationLabel,
      relayStrength: relayStrength ?? this.relayStrength,
    );
  }

  double get presenceScore => (signalStrength * 0.6) + (relayStrength * 0.4);

  static MeshPeer sample({
    required String id,
    required String name,
    required MeshPeerRole role,
    required String locationLabel,
    required double signalStrength,
    required double batteryLevel,
    required double relayStrength,
  }) {
    return MeshPeer(
      id: id,
      name: name,
      role: role,
      signalStrength: signalStrength,
      batteryLevel: batteryLevel,
      lastSeen: DateTime.now(),
      locationLabel: locationLabel,
      relayStrength: relayStrength,
    );
  }

  MeshPeer jittered(Random random) {
    final signalDelta = (random.nextDouble() * 10) - 5;
    final relayDelta = (random.nextDouble() * 8) - 4;
    final batteryDelta = random.nextDouble() * 1.2;
    return copyWith(
      signalStrength: (signalStrength + signalDelta).clamp(18, 100),
      relayStrength: (relayStrength + relayDelta).clamp(10, 100),
      batteryLevel: (batteryLevel - batteryDelta).clamp(10, 100),
      lastSeen: DateTime.now(),
    );
  }
}