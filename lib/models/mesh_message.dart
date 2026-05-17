enum MeshMessageType { text, location, emergency, image }

enum MeshMessagePriority { normal, elevated, critical }

class MeshMessage {
  const MeshMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.type,
    required this.priority,
    required this.body,
    required this.createdAt,
    required this.ttl,
    required this.hops,
    required this.route,
    required this.encrypted,
    required this.acknowledged,
    required this.metadata,
  });

  final String id;
  final String senderId;
  final String senderName;
  final MeshMessageType type;
  final MeshMessagePriority priority;
  final String body;
  final DateTime createdAt;
  final int ttl;
  final int hops;
  final List<String> route;
  final bool encrypted;
  final bool acknowledged;
  final Map<String, dynamic> metadata;

  MeshMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    MeshMessageType? type,
    MeshMessagePriority? priority,
    String? body,
    DateTime? createdAt,
    int? ttl,
    int? hops,
    List<String>? route,
    bool? encrypted,
    bool? acknowledged,
    Map<String, dynamic>? metadata,
  }) {
    return MeshMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      type: type ?? this.type,
      priority: priority ?? this.priority,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      ttl: ttl ?? this.ttl,
      hops: hops ?? this.hops,
      route: route ?? this.route,
      encrypted: encrypted ?? this.encrypted,
      acknowledged: acknowledged ?? this.acknowledged,
      metadata: metadata ?? this.metadata,
    );
  }

  bool get isExpired => ttl <= 0;

  bool get isUrgent => priority == MeshMessagePriority.critical;

  String get routeLabel => route.isEmpty ? 'Local' : route.join(' -> ');
}