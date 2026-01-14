import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/printer_service.dart';
import '../../../../core/services/session_service.dart';
import '../../../../data/models/transaction.dart';
import '../../../../data/models/transaction_item.dart';
import '../../../widgets/printer_selection_dialog.dart';
import 'receipt_widget.dart';

/// Print Settings Dialog
/// Shows a dummy receipt preview and allows connecting/testing printer
class PrintSettingsDialog extends StatelessWidget {
  const PrintSettingsDialog({super.key});

  /// Show print settings dialog
  static Future<void> show(BuildContext context) {
    return showDialog(context: context, builder: (ctx) => const PrintSettingsDialog());
  }

  // Dummy transaction for preview
  Transaction get _dummyTransaction {
    return Transaction(
      kodeTransaksi: 'TRX-TEST-001',
      items: [
        const TransactionItem(
          produkId: 1,
          namaProduk: 'Potong Rambut Dewasa',
          hargaSatuan: 35000,
          jumlah: 1,
          subtotal: 35000,
        ),
        const TransactionItem(
          produkId: 2,
          namaProduk: 'Pomade Waterbased',
          hargaSatuan: 65000,
          jumlah: 1,
          subtotal: 65000,
        ),
      ],
      totalHarga: 100000,
      totalBayar: 100000,
      totalKembalian: 0,
      metodePembayaran: 'Tunai',
      statusTransaksi: TransactionStatus.selesai,
      userId: 1,
      createdAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                maxWidth: 340, // Slightly wider for settings
                maxHeight: screenHeight * 0.85,
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 24),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text('Pengaturan Print', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                      ],
                    ),
                    const Divider(),

                    const SizedBox(height: 8),
                    const Text(
                      'Preview Struk',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),

                    // Receipt Preview (scrollable)
                    Flexible(
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade200),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey.shade50,
                        ),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(8),
                          child: ReceiptWidget(
                            transaction: _dummyTransaction,
                            cashierName: SessionService.instance.userName ?? 'Kasir',
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Printer Status Section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: printer.isConnected ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        border: Border.all(
                          color: printer.isConnected ? Colors.green.withOpacity(0.3) : Colors.orange.withOpacity(0.3),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            printer.isConnected ? Icons.check_circle : Icons.info_outline,
                            color: printer.isConnected ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  printer.isConnected ? 'Printer Terhubung' : 'Printer Tidak Terhubung',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: printer.isConnected ? Colors.green.shade700 : Colors.orange.shade700,
                                  ),
                                ),
                                if (printer.isConnected)
                                  Text(
                                    printer.connectedDevice?.name ?? 'Unknown Device',
                                    style: TextStyle(fontSize: 12, color: Colors.green.shade700),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        // Connect/Change Printer
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => PrinterSelectionDialog.show(context),
                            icon: const Icon(Icons.bluetooth_searching),
                            label: Text(printer.isConnected ? 'Ganti' : 'Hubungkan'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Test Print
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: printer.isConnected && !printer.isPrinting
                                ? () async {
                                    final success = await printer.printReceipt(
                                      transaction: _dummyTransaction,
                                      cashierName: SessionService.instance.userName ?? 'Kasir',
                                    );
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(success ? '✅ Test print berhasil!' : '❌ Test print gagal!'),
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
                            label: Text(printer.isPrinting ? 'Mencetak...' : 'Test Print'),
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
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
