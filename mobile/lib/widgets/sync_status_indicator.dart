import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sync_service.dart';

class SyncStatusIndicator extends StatelessWidget {
  const SyncStatusIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    final syncService = context.watch<SyncService>();
    final status = syncService.status;

    Color color;
    String label;
    bool shouldPulsate = false;

    switch (status) {
      case SyncState.online:
        color = const Color(0xFF10B981); // Emerald Green
        label = 'Cloud Connected';
        break;
      case SyncState.syncing:
        color = const Color(0xFF3B82F6); // Modern Blue
        label = 'Pulling remote changes...';
        shouldPulsate = true;
        break;
      case SyncState.disabled:
        color = const Color(0xFF94A3B8); // Slate Grey
        label = 'Cloud Disabled';
        break;
      case SyncState.offline:
        color = const Color(0xFFEF4444); // Error Red
        label = 'Cloud Offline';
        break;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlowingDot(
            color: color,
            isPulsating: shouldPulsate,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.9),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _GlowingDot extends StatefulWidget {
  final Color color;
  final bool isPulsating;

  const _GlowingDot({
    required this.color,
    required this.isPulsating,
  });

  @override
  State<_GlowingDot> createState() => _GlowingDotState();
}

class _GlowingDotState extends State<_GlowingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    if (widget.isPulsating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_GlowingDot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPulsating && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPulsating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final opacity = widget.isPulsating ? _animation.value : 1.0;
        return Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color.withValues(alpha: opacity),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: opacity * 0.6),
                blurRadius: widget.isPulsating ? 8 * _animation.value : 6,
                spreadRadius: widget.isPulsating ? 2 * _animation.value : 1,
              ),
            ],
          ),
        );
      },
    );
  }
}
