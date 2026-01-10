import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/connectivity_service.dart';
import '../../../../core/sync/sync_status.dart';
import '../../../widgets/sync_status_badge.dart';

/// Success Dialog Widget
/// Shows transaction success confirmation with sync status
class SuccessDialog extends StatelessWidget {
  final VoidCallback onPrintReceipt;
  final VoidCallback onNewTransaction;

  const SuccessDialog({super.key, required this.onPrintReceipt, required this.onNewTransaction});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final connectivity = ConnectivityService.instance;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.check, size: 48, color: Color(0xFF10B981)),
            ),

            const SizedBox(height: 24),

            // Title
            Text('Transaksi Berhasil!', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),

            const SizedBox(height: 8),

            // Description & Sync Status - depends on connectivity
            ChangeNotifierProvider.value(
              value: connectivity,
              child: Consumer<ConnectivityService>(
                builder: (context, conn, _) {
                  final isOnline = conn.isOnline;

                  return Column(
                    children: [
                      Text(
                        isOnline
                            ? 'Pembayaran telah diterima dan\nstok produk telah diperbarui.'
                            : 'Transaksi tersimpan secara lokal.\nAkan disinkronkan saat online.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 12),
                      // Sync Status Badge
                      SyncStatusBadge(status: isOnline ? SyncStatus.synced : SyncStatus.pending, showLabel: true),
                    ],
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // Print Receipt Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onPrintReceipt,
                icon: const Icon(Icons.print_outlined),
                label: const Text('Cetak Struk'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // New Transaction Button
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  // Show confirmation dialog
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Konfirmasi'),
                      content: const Text(
                        'Apakah Anda yakin ingin memulai transaksi baru?\n\nPastikan struk sudah dicetak jika diperlukan.',
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Ya, Lanjutkan')),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    onNewTransaction();
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Transaksi Baru'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
