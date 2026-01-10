import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../data/models/transaction.dart';
import '../../../widgets/printer_selection_dialog.dart';
import 'receipt_widget.dart';

/// Receipt Dialog
/// Shows a preview of the receipt with option to print
class ReceiptDialog extends StatelessWidget {
  final Transaction transaction;
  final VoidCallback? onClose;

  const ReceiptDialog({super.key, required this.transaction, this.onClose});

  /// Show receipt dialog
  static Future<void> show(BuildContext context, {required Transaction transaction}) {
    debugPrint('🖨️ Opening receipt dialog for ${transaction.kodeTransaksi}');
    return showDialog(
      context: context,
      barrierDismissible: false, // Can only close via button
      builder: (ctx) => ReceiptDialog(transaction: transaction, onClose: () => Navigator.pop(ctx)),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🖨️ Building receipt dialog');

    // Get screen height for max constraint
    final screenHeight = MediaQuery.of(context).size.height;

    return ChangeNotifierProvider.value(
      value: PrinterService.instance,
      child: Consumer<PrinterService>(
        builder: (context, printer, _) {
          return Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: 320, // Compact width
                maxHeight: screenHeight * 0.75, // Max 75% of screen height
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Receipt Preview (scrollable)
                    Flexible(
                      child: SingleChildScrollView(child: ReceiptWidget(transaction: transaction)),
                    ),

                    const SizedBox(height: 16),

                    // Printer Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: printer.isConnected ? Colors.green.withOpacity(0.9) : Colors.orange.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(printer.isConnected ? Icons.print : Icons.print_disabled, size: 16, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            printer.isConnected ? (printer.connectedDevice?.name ?? 'Printer') : 'Belum ada printer',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Action Buttons - Vertical layout
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Print Button (Primary)
                        FilledButton.icon(
                          onPressed: printer.isConnected && !printer.isPrinting
                              ? () async {
                                  final success = await printer.printReceipt(transaction: transaction);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(success ? '✅ Struk berhasil dicetak' : '❌ Gagal mencetak struk'),
                                        backgroundColor: success ? Colors.green : Colors.red,
                                      ),
                                    );
                                  }
                                }
                              : null,
                          icon: printer.isPrinting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.print),
                          label: Text(printer.isPrinting ? 'Mencetak...' : 'Cetak Struk'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Connect Printer Button
                        OutlinedButton.icon(
                          onPressed: () => PrinterSelectionDialog.show(context),
                          icon: const Icon(Icons.bluetooth),
                          label: Text(printer.isConnected ? 'Ganti Printer' : 'Hubungkan Printer'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Close Button
                        TextButton(
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Tutup Struk?'),
                                content: const Text('Pastikan struk sudah dicetak jika diperlukan.'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    child: const Text('Ya, Tutup'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              if (onClose != null) {
                                onClose!();
                              } else if (context.mounted) {
                                Navigator.pop(context);
                              }
                            }
                          },
                          child: const Text('Tutup'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
