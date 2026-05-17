class MeshLink {
  const MeshLink({
    required this.fromId,
    required this.toId,
    required this.strength,
    required this.active,
    required this.label,
  });

  final String fromId;
  final String toId;
  final double strength;
  final bool active;
  final String label;
}