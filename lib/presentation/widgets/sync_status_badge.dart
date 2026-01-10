import 'package:flutter/material.dart';

import '../../core/sync/sync_status.dart';

/// Sync Status Badge Widget
/// Shows a small badge indicating sync status
class SyncStatusBadge extends StatelessWidget {
  final SyncStatus status;
  final bool showLabel;

  const SyncStatusBadge({super.key, required this.status, this.showLabel = false});

  @override
  Widget build(BuildContext context) {
    final (icon, color, label) = switch (status) {
      SyncStatus.synced => (Icons.cloud_done, Colors.green, 'Tersinkron'),
      SyncStatus.pending => (Icons.cloud_upload, Colors.orange, 'Menunggu'),
      SyncStatus.syncing => (Icons.sync, Colors.blue, 'Menyinkron...'),
      SyncStatus.failed => (Icons.cloud_off, Colors.red, 'Gagal sync'),
    };

    if (showLabel) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
      child: Icon(icon, size: 12, color: color),
    );
  }
}
