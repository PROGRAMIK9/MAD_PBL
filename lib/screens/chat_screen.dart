import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/mesh_message.dart';
import '../services/mesh_store.dart';
import '../widgets/status_chip.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.store});

  final MeshStore store;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

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
            title: const Text('Offline Chat'),
            actions: <Widget>[
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Center(
                  child: StatusChip(
                    label: widget.store.meshEnabled ? 'Mesh live' : 'Mesh paused',
                    color: widget.store.meshEnabled ? const Color(0xFF43D6A7) : const Color(0xFFFB7185),
                    icon: widget.store.meshEnabled ? Icons.wifi : Icons.wifi_off,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16),
                child: _ComposerCard(
                  controller: _controller,
                  onSend: _sendMessage,
                  onImage: widget.store.injectCompressedImageRelay,
                  onLocation: () => widget.store.shareLocation('Field Cache', 40.7132, -74.0051),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: widget.store.messages.length,
                  separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 12),
                  itemBuilder: (BuildContext context, int index) {
                    final MeshMessage message = widget.store.messages[index];
                    return _MessageCard(message: message);
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _sendMessage() {
    widget.store.sendText(_controller.text);
    _controller.clear();
  }
}

class _ComposerCard extends StatelessWidget {
  const _ComposerCard({required this.controller, required this.onSend, required this.onImage, required this.onLocation});

  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onImage;
  final VoidCallback onLocation;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1425),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: <Widget>[
          TextField(
            controller: controller,
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              hintText: 'Write a local mesh message...',
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              TextButton.icon(onPressed: onLocation, icon: const Icon(Icons.my_location), label: const Text('Share location')),
              const SizedBox(width: 8),
              TextButton.icon(onPressed: onImage, icon: const Icon(Icons.image_outlined), label: const Text('Compressed image')),
              const Spacer(),
              FilledButton.icon(onPressed: onSend, icon: const Icon(Icons.send), label: const Text('Send')),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final MeshMessage message;

  @override
  Widget build(BuildContext context) {
    final Color accent = switch (message.priority) {
      MeshMessagePriority.critical => const Color(0xFFFF6B6B),
      MeshMessagePriority.elevated => const Color(0xFFFFC857),
      MeshMessagePriority.normal => const Color(0xFF4D9EFF),
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1425),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_iconFor(message.type), color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(message.senderName, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.white, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(message.routeLabel, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white60)),
                  ],
                ),
              ),
              Text(DateFormat('HH:mm').format(message.createdAt), style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.white54)),
            ],
          ),
          const SizedBox(height: 14),
          Text(message.body, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.white, height: 1.4)),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              _InfoTag(text: message.priority.name.toUpperCase(), color: accent),
              _InfoTag(text: '${message.hops} hops', color: const Color(0xFF43D6A7)),
              _InfoTag(text: message.encrypted ? 'AES-256 encrypted' : 'plain text', color: const Color(0xFF4D9EFF)),
              _InfoTag(text: message.acknowledged ? 'ACK received' : 'waiting ACK', color: const Color(0xFFFFC857)),
            ],
          ),
        ],
      ),
    );
  }

  IconData _iconFor(MeshMessageType type) {
    return switch (type) {
      MeshMessageType.text => Icons.chat_bubble_outline,
      MeshMessageType.location => Icons.location_on_outlined,
      MeshMessageType.emergency => Icons.warning_amber_outlined,
      MeshMessageType.image => Icons.image_outlined,
    };
  }
}

class _InfoTag extends StatelessWidget {
  const _InfoTag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(color: color.withOpacity(0.14), borderRadius: BorderRadius.circular(999)),
      child: Text(text, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: color, fontWeight: FontWeight.w600)),
    );
  }
}