import 'package:flutter/material.dart';

import '../models/mesh_link.dart';
import '../models/mesh_peer.dart';
import '../services/mesh_store.dart';
import '../widgets/status_chip.dart';

class TopologyScreen extends StatelessWidget {
  const TopologyScreen({super.key, required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Mesh Topology')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _SummaryHeader(store: store),
              const SizedBox(height: 16),
              _TopologyCanvas(store: store),
              const SizedBox(height: 16),
              _PeerList(store: store),
              const SizedBox(height: 16),
              _LinkList(store: store),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF0B1425), Color(0xFF09101C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const StatusChip(label: 'Topology live', color: Color(0xFF4D9EFF), icon: Icons.route),
          const SizedBox(height: 12),
          Text('Nodes discover one another and relay packets through the best available path.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${store.activePeers} peers online • ${store.relayNodes} relay-capable nodes • ${store.acknowledgedMessages} acked messages', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _TopologyCanvas extends StatelessWidget {
  const _TopologyCanvas({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 380,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1425),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: CustomPaint(
        painter: _TopologyPainter(peers: store.peers, links: store.links),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _PeerList extends StatelessWidget {
  const _PeerList({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Nearby nodes',
      child: Column(
        children: store.peers
            .map(
              (MeshPeer peer) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PeerTile(peer: peer),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _LinkList extends StatelessWidget {
  const _LinkList({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Active relay links',
      child: Column(
        children: store.links
            .map(
              (MeshLink link) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.hub_outlined, color: Color(0xFF43D6A7)),
                title: Text('${link.fromId} → ${link.toId}', style: const TextStyle(color: Colors.white)),
                subtitle: Text(link.label, style: const TextStyle(color: Colors.white54)),
                trailing: Text('${link.strength.toStringAsFixed(0)}%', style: const TextStyle(color: Colors.white70)),
              ),
            )
            .toList(growable: false),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1425),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _PeerTile extends StatelessWidget {
  const _PeerTile({required this.peer});

  final MeshPeer peer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF4D9EFF).withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.person_pin_circle_outlined, color: Color(0xFF4D9EFF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(peer.name, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text('${peer.locationLabel} • ${peer.role.name}', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text('${peer.signalStrength.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelLarge?.copyWith(color: Colors.white)),
              const SizedBox(height: 3),
              Text('relay ${peer.relayStrength.toStringAsFixed(0)}%', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopologyPainter extends CustomPainter {
  _TopologyPainter({required this.peers, required this.links});

  final List<MeshPeer> peers;
  final List<MeshLink> links;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint background = Paint()..color = const Color(0xFF09101C);
    canvas.drawRect(Offset.zero & size, background);

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final Offset center = Offset(size.width / 2, size.height / 2);
    final List<Offset> nodePositions = <Offset>[
      center,
      Offset(size.width * 0.2, size.height * 0.25),
      Offset(size.width * 0.78, size.height * 0.22),
      Offset(size.width * 0.16, size.height * 0.74),
      Offset(size.width * 0.78, size.height * 0.73),
      Offset(size.width * 0.50, size.height * 0.16),
    ];

    final Paint linkPaint = Paint()
      ..color = const Color(0xFF43D6A7).withOpacity(0.45)
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    for (final MeshLink link in links) {
      final int fromIndex = _indexFor(link.fromId);
      final int toIndex = _indexFor(link.toId);
      final Offset from = nodePositions[fromIndex % nodePositions.length];
      final Offset to = nodePositions[toIndex % nodePositions.length];
      canvas.drawLine(from, to, linkPaint);
      canvas.drawCircle(Offset.lerp(from, to, 0.5)!, 3.5, Paint()..color = const Color(0xFFFFC857));
    }

    final Paint nodePaint = Paint()..color = const Color(0xFF4D9EFF);
    final Paint relayPaint = Paint()..color = const Color(0xFFFFC857);

    for (int index = 0; index < nodePositions.length && index < peers.length + 1; index += 1) {
      final Offset point = nodePositions[index];
      final bool isCenter = index == 0;
      canvas.drawCircle(point, isCenter ? 18 : 13, isCenter ? relayPaint : nodePaint);
      canvas.drawCircle(point, isCenter ? 24 : 18, Paint()..color = Colors.white.withOpacity(0.08)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  int _indexFor(String id) {
    if (id == 'node-local-01') {
      return 0;
    }
    return peers.indexWhere((MeshPeer peer) => peer.id == id) + 1;
  }

  @override
  bool shouldRepaint(covariant _TopologyPainter oldDelegate) {
    return oldDelegate.peers != peers || oldDelegate.links != links;
  }
}