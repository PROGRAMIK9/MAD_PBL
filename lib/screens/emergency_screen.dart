import 'package:flutter/material.dart';

import '../services/mesh_store.dart';
import '../widgets/status_chip.dart';

class EmergencyScreen extends StatefulWidget {
  const EmergencyScreen({super.key, required this.store});

  final MeshStore store;

  @override
  State<EmergencyScreen> createState() => _EmergencyScreenState();
}

class _EmergencyScreenState extends State<EmergencyScreen> {
  final TextEditingController _controller = TextEditingController(
    text: 'Building collapsed near Gate 3',
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.store,
      builder: (BuildContext context, Widget? child) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Emergency Broadcast'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: StatusChip(
                    label: widget.store.disasterMode ? 'Disaster mode on' : 'Standard mode',
                    color: widget.store.disasterMode ? const Color(0xFFFFC857) : const Color(0xFF4D9EFF),
                    icon: Icons.campaign_outlined,
                  ),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              _HeroPanel(store: widget.store),
              const SizedBox(height: 16),
              _BroadcastCard(controller: _controller, store: widget.store),
              const SizedBox(height: 16),
              _TemplateCard(store: widget.store),
              const SizedBox(height: 16),
              _RoutingCard(store: widget.store),
            ],
          ),
        );
      },
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF2B1020), Color(0xFF130B17), Color(0xFF08111F)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const StatusChip(label: 'Priority relay path', color: Color(0xFFFF6B6B), icon: Icons.priority_high),
          const SizedBox(height: 14),
          Text(
            'Broadcast emergency alerts across nearby devices with repeated relays and ACK tracking.',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          Text(
            'Critical packets jump the queue and remain visible until acknowledged by the mesh.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _BroadcastCard extends StatelessWidget {
  const _BroadcastCard({required this.controller, required this.store});

  final TextEditingController controller;
  final MeshStore store;

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
          Text('Broadcast message', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Describe what nearby devices must relay...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              FilledButton.icon(
                onPressed: () => store.sendEmergency(controller.text),
                icon: const Icon(Icons.campaign),
                label: const Text('Broadcast'),
              ),
              const SizedBox(width: 10),
              OutlinedButton.icon(
                onPressed: () => store.sendEmergency('Medical support needed near Gate 3'),
                icon: const Icon(Icons.medical_services_outlined),
                label: const Text('Medical'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({required this.store});

  final MeshStore store;

  @override
  Widget build(BuildContext context) {
    final List<_TemplateItem> templates = <_TemplateItem>[
      _TemplateItem('Collapsed building', 'Building collapsed near Gate 3', Icons.domain_disabled_outlined),
      _TemplateItem('Evacuation route', 'Safe path open from west exit', Icons.alt_route),
      _TemplateItem('Medical support', 'Need triage team at shelter 2', Icons.local_hospital_outlined),
      _TemplateItem('Search team', 'Relay search team to south aisle', Icons.search_outlined),
    ];

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
          Text('Quick templates', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: templates
                .map(
                  (_TemplateItem item) => ActionChip(
                    avatar: Icon(item.icon, size: 18, color: const Color(0xFFFFC857)),
                    label: Text(item.label),
                    onPressed: () => store.sendEmergency(item.message),
                  ),
                )
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}

class _RoutingCard extends StatelessWidget {
  const _RoutingCard({required this.store});

  final MeshStore store;

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
          Text('Emergency routing', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('${store.acknowledgedMessages} acknowledged • ${store.emergencyMessages} critical packets queued', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
          const SizedBox(height: 14),
          LinearProgressIndicator(value: store.acknowledgedMessages == 0 ? 0.25 : 0.75, minHeight: 10, borderRadius: BorderRadius.circular(999)),
          const SizedBox(height: 14),
          Text('Emergency relays are repeated across the mesh until at least one device confirms receipt.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70)),
        ],
      ),
    );
  }
}

class _TemplateItem {
  const _TemplateItem(this.label, this.message, this.icon);

  final String label;
  final String message;
  final IconData icon;
}