import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/sync_manager.dart';
import '../../core/sync/sync_status.dart';

/// Sync Indicator Widget
/// Shows a small floating indicator when items are syncing or recently synced
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: SyncManager.instance,
      child: Consumer<SyncManager>(
        builder: (context, syncManager, _) {
          // Don't show if nothing pending and no recent syncs
          if (!syncManager.hasPending && syncManager.recentSynced.isEmpty) {
            return const SizedBox.shrink();
          }

          return Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Center(child: _SyncBadge(syncManager: syncManager)),
          );
        },
      ),
    );
  }
}

class _SyncBadge extends StatefulWidget {
  final SyncManager syncManager;

  const _SyncBadge({required this.syncManager});

  @override
  State<_SyncBadge> createState() => _SyncBadgeState();
}

class _SyncBadgeState extends State<_SyncBadge> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _showSuccess = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void didUpdateWidget(_SyncBadge oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if something just synced
    if (widget.syncManager.recentSynced.isNotEmpty && !widget.syncManager.hasPending) {
      _showSuccess = true;
      // Auto-hide after 3 seconds
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() => _showSuccess = false);
          widget.syncManager.clearRecentSynced();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPending = widget.syncManager.hasPending;
    final pendingCount = widget.syncManager.pendingCount;
    final recentCount = widget.syncManager.recentSynced.length;

    // Show success if just synced
    if (_showSuccess && recentCount > 0 && !hasPending) {
      return _buildBadge(icon: Icons.cloud_done, color: Colors.green, label: '$recentCount tersinkron', animate: false);
    }

    // Show pending count if syncing
    if (hasPending) {
      return _buildBadge(icon: Icons.sync, color: Colors.orange, label: '$pendingCount menunggu', animate: true);
    }

    return const SizedBox.shrink();
  }

  Widget _buildBadge({required IconData icon, required Color color, required String label, required bool animate}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          animate
              ? RotationTransition(
                  turns: _controller,
                  child: Icon(icon, size: 18, color: Colors.white),
                )
              : Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
