import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/services/printer_service.dart';

/// Printer Selection Dialog
/// Shows a dialog to scan, select, and connect to a Bluetooth printer
class PrinterSelectionDialog extends StatelessWidget {
  final VoidCallback? onConnected;

  const PrinterSelectionDialog({super.key, this.onConnected});

  /// Show printer selection dialog
  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => PrinterSelectionDialog(onConnected: () => Navigator.pop(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ChangeNotifierProvider.value(
      value: PrinterService.instance,
      child: Consumer<PrinterService>(
        builder: (context, printer, _) {
          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.print, size: 24),
                const SizedBox(width: 8),
                const Expanded(child: Text('Pilih Printer')),
                if (printer.isConnected)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, size: 14, color: Colors.green),
                        SizedBox(width: 4),
                        Text('Terhubung', style: TextStyle(fontSize: 11, color: Colors.green)),
                      ],
                    ),
                  ),
              ],
            ),
            content: SizedBox(
              width: 300,
              height: 300,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Scan Button
                  FilledButton.icon(
                    onPressed: printer.isScanning ? null : () => printer.startScan(),
                    icon: printer.isScanning
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.bluetooth_searching),
                    label: Text(printer.isScanning ? 'Mencari...' : 'Cari Printer'),
                  ),
                  const SizedBox(height: 16),

                  // Connected Printer
                  if (printer.isConnected) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.print, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  printer.connectedDevice!.name ?? 'Unknown',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  printer.connectedDevice!.address ?? '',
                                  style: TextStyle(fontSize: 11, color: colorScheme.outline),
                                ),
                              ],
                            ),
                          ),
                          TextButton(onPressed: () => printer.disconnect(), child: const Text('Putus')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Device List
                  Expanded(
                    child: printer.devices.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.bluetooth_disabled, size: 48, color: colorScheme.outline),
                                const SizedBox(height: 8),
                                Text(
                                  'Belum ada printer ditemukan\nTekan "Cari Printer" untuk scan',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: colorScheme.outline),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            itemCount: printer.devices.length,
                            itemBuilder: (context, index) {
                              final device = printer.devices[index];
                              final isConnected = printer.connectedDevice?.address == device.address;

                              return ListTile(
                                leading: Icon(Icons.print, color: isConnected ? Colors.green : colorScheme.onSurface),
                                title: Text(device.name ?? 'Unknown Device'),
                                subtitle: Text(device.address ?? ''),
                                trailing: isConnected ? const Icon(Icons.check_circle, color: Colors.green) : null,
                                onTap: isConnected
                                    ? null
                                    : () async {
                                        final success = await printer.connect(device);
                                        if (success && context.mounted) {
                                          onConnected?.call();
                                        }
                                      },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
              if (printer.isConnected)
                FilledButton(
                  onPressed: () => Navigator.pop(context, printer.connectedDevice),
                  child: const Text('Gunakan Printer Ini'),
                ),
            ],
          );
        },
      ),
    );
  }
}
