// Relay service scaffold: deduplication and store-and-forward helpers
import 'dart:async';

class RelayService {
  final Set<String> _seen = <String>{};
  final StreamController<Map<String, dynamic>> _incomingController =
      StreamController.broadcast();

  Stream<Map<String, dynamic>> get incoming => _incomingController.stream;

  void start() {
    // Start any periodic tasks (persistence, GC) here.
  }

  void stop() {
    _incomingController.close();
  }

  bool acceptPacket(Map<String, dynamic> packet) {
    final id = packet['id']?.toString();
    if (id == null) return false;
    if (_seen.contains(id)) return false;
    _seen.add(id);
    _incomingController.add(packet);
    return true;
  }

  void markRelayed(String id) {
    // Optionally track relay state, TTL, or remove from _seen after expiry.
  }
}
