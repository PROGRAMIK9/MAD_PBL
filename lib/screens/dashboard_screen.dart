import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mesh_activity.dart';
import '../services/mesh_store.dart';
import '../widgets/status_chip.dart';
import '../widgets/summary_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: store,
      builder: (BuildContext context, Widget? child) {
        return CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              pinned: true,
              expandedHeight: 184,
              backgroundColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding: const EdgeInsetsDirectional.only(start: 20, bottom: 16),
                title: Text(store.networkLabel),
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: <Color>[Color(0xFF0A1630), Color(0xFF08111F), Color(0xFF04070D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(20, 72, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      const StatusChip(label: 'Offline relay active', color: Color(0xFF43D6A7), icon: Icons.sensors),
                      const SizedBox(height: 14),
                      Text(
                        'Mesh links keep the network alive when towers go down.',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: <Widget>[
                IconButton(
                  onPressed: store.toggleMesh,
                  icon: Icon(store.meshEnabled ? Icons.wifi : Icons.wifi_off),
                ),
                IconButton(
                  onPressed: store.toggleDisasterMode,
                  icon: const Icon(Icons.battery_saver),
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    GridView.count(
                      crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 14,
                      crossAxisSpacing: 14,
                      childAspectRatio: 1.3,
                      children: <Widget>[
                        SummaryCard(
                          title: 'Active peers',
                          value: store.activePeers.toString(),
                          subtitle: store.coverageLabel,
                          icon: Icons.people_alt_outlined,
                          accent: const Color(0xFF4D9EFF),
                        ),
                        SummaryCard(
                          title: 'Emergency queue',
                          value: store.emergencyMessages.toString(),
                          subtitle: 'Critical relays with retry priority',
                          icon: Icons.warning_amber_outlined,
                          accent: const Color(0xFFFFC857),
                        ),
                        SummaryCard(
                          title: 'Relay health',
                          value: '${store.averageRelayStrength.toStringAsFixed(0)}%',
                          subtitle: 'Average presence score across nodes',
                          icon: Icons.route_outlined,
                          accent: const Color(0xFF43D6A7),
                        ),
                        SummaryCard(
                          title: 'Battery safe mode',
                          value: '${store.batteryLevel.toStringAsFixed(0)}%',
                          subtitle: store.disasterMode ? 'Adaptive scan interval enabled' : 'Standard sync cadence',
                          icon: Icons.battery_full_outlined,
                          accent: const Color(0xFFFB7185),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _PanelCard(
                      title: 'Live network state',
                      subtitle: store.syncState,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 4),
                          Row(
                            children: <Widget>[
                              const Icon(Icons.schedule_outlined, color: Colors.white60, size: 18),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEE, MMM d • HH:mm').format(DateTime.now()),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          LinearProgressIndicator(
                            minHeight: 10,
                            value: store.offlineSignal / 100,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Signal availability ${store.offlineSignal.toStringAsFixed(0)}% across the nearest mesh perimeter.',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _PanelCard(
                      title: 'Recent activity',
                      subtitle: 'Relay events and emergency updates',
                      child: Column(
                        children: store.activities
                            .map(
                              (MeshActivity activity) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _ActivityTile(
                                  title: activity.title,
                                  subtitle: activity.subtitle,
                                  level: activity.level,
                                  time: DateFormat('HH:mm').format(activity.timestamp),
                                ),
                              ),
                            )
                            .toList(growable: false),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PanelCard extends StatelessWidget {
  const _PanelCard({required this.title, required this.subtitle, required this.child});

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.title, required this.subtitle, required this.level, required this.time});

  final String title;
  final String subtitle;
  final String level;
  final String time;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (level) {
      'critical' => const Color(0xFFFF6B6B),
      'warning' => const Color(0xFFFFC857),
      _ => const Color(0xFF43D6A7),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 12,
            height: 12,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
              ],
            ),
          ),
          Text(time, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
        ],
      ),
    );
  }
}