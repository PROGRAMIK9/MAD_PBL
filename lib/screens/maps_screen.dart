import 'dart:ui' as ui;
import 'package:flutter/material.dart';

import '../models/mesh_location.dart';
import '../services/mesh_store.dart';
import '../widgets/status_chip.dart';

class MapsScreen extends StatelessWidget {
  const MapsScreen({super.key, required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(title: const Text('Offline Rescue Map')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _Hero(store: store),
              const SizedBox(height: 16),
              _MapPanel(store: store),
              const SizedBox(height: 16),
              _LocationList(store: store),
            ],
          ),
        );
      },
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF091B2C), Color(0xFF07101C), Color(0xFF04070D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const StatusChip(label: 'Offline tiles ready', color: Color(0xFF43D6A7), icon: Icons.map_outlined),
          const SizedBox(height: 12),
          Text('GPS sharing and hazard marking continue even when there is no internet connection.', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Pre-downloaded map areas can show safe paths, danger zones, and rescue check-ins.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
        ],
      ),
    );
  }
}

class _MapPanel extends StatelessWidget {
  const _MapPanel({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        color: const Color(0xFF0B1425),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Stack(
        children: <Widget>[
          Positioned.fill(child: CustomPaint(painter: _MapPainter(locations: store.locations))),
          Positioned(
            left: 16,
            top: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                StatusChip(label: '${store.locations.length} markers active', color: const Color(0xFFFFC857), icon: Icons.place_outlined),
                const SizedBox(height: 8),
                StatusChip(label: 'Live GPS without internet', color: const Color(0xFF4D9EFF), icon: Icons.gps_fixed),
              ],
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: FilledButton.icon(
              onPressed: () => store.shareLocation('Fresh safety pin', 40.7139, -74.0048),
              icon: const Icon(Icons.add_location_alt_outlined),
              label: const Text('Mark point'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationList extends StatelessWidget {
  const _LocationList({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: store.locations
          .map(
            (MeshLocation location) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0B1425),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(_iconFor(location.kind), color: const Color(0xFF4D9EFF)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(location.label, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text(location.note, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}', style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
                  ],
                ),
              ),
            ),
          )
          .toList(growable: false),
    );
  }

  IconData _iconFor(MeshLocationKind kind) {
    return switch (kind) {
      MeshLocationKind.safePath => Icons.alt_route,
      MeshLocationKind.dangerZone => Icons.dangerous_outlined,
      MeshLocationKind.rescuePoint => Icons.local_hospital_outlined,
      MeshLocationKind.relayBeacon => Icons.hub_outlined,
    };
  }
}

class _MapPainter extends CustomPainter {
  _MapPainter({required this.locations});

  final List<MeshLocation> locations;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFF09101C));

    final Paint gridPaint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += 32) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y <= size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final List<Offset> route = <Offset>[
      Offset(size.width * 0.12, size.height * 0.75),
      Offset(size.width * 0.28, size.height * 0.60),
      Offset(size.width * 0.46, size.height * 0.44),
      Offset(size.width * 0.66, size.height * 0.32),
      Offset(size.width * 0.84, size.height * 0.22),
    ];

    final Paint safePaint = Paint()
      ..color = const Color(0xFF43D6A7)
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPoints(ui.PointMode.polygon, route, safePaint);

    final Paint dangerPaint = Paint()..color = const Color(0xFFFF6B6B).withOpacity(0.8);
    final Paint rescuePaint = Paint()..color = const Color(0xFFFFC857).withOpacity(0.9);

    if (locations.isNotEmpty) {
      canvas.drawCircle(route[2], 18, dangerPaint);
      canvas.drawCircle(route[4], 16, rescuePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _MapPainter oldDelegate) => oldDelegate.locations != locations;
}