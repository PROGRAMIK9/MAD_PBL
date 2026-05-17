enum MeshLocationKind { safePath, dangerZone, rescuePoint, relayBeacon }

class MeshLocation {
  const MeshLocation({
    required this.label,
    required this.latitude,
    required this.longitude,
    required this.kind,
    required this.note,
  });

  final String label;
  final double latitude;
  final double longitude;
  final MeshLocationKind kind;
  final String note;
}