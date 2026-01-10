import 'dart:async';
import 'package:bluetooth_print_plus/bluetooth_print_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import '../../data/models/transaction.dart';

/// Printer Service
/// Handles Bluetooth thermal printer connection and printing
class PrinterService extends ChangeNotifier {
  static PrinterService? _instance;

  BluetoothDevice? _connectedDevice;
  List<BluetoothDevice> _devices = [];

  StreamSubscription<List<BluetoothDevice>>? _scanResultsSubscription;
  StreamSubscription<ConnectState>? _connectStateSubscription;
  bool _isPrinting = false;

  PrinterService._() {
    _initListeners();
  }

  static PrinterService get instance {
    _instance ??= PrinterService._();
    return _instance!;
  }

  void _initListeners() {
    // Listen to scan results
    _scanResultsSubscription = BluetoothPrintPlus.scanResults.listen((event) {
      _devices = event;
      notifyListeners();

      if (kDebugMode) {
        print('🔍 Found ${event.length} devices');
      }
    });

    // Listen to connect state
    _connectStateSubscription = BluetoothPrintPlus.connectState.listen((event) {
      if (kDebugMode) {
        print('🔌 Connect state: $event');
      }

      if (event == ConnectState.disconnected) {
        _connectedDevice = null;
        notifyListeners();
      }
    });
  }

  // Getters
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isScanning => BluetoothPrintPlus.isScanningNow;
  bool get isPrinting => _isPrinting;
  List<BluetoothDevice> get devices => _devices;
  bool get isBluetoothOn => BluetoothPrintPlus.isBlueOn;

  /// Start scanning for Bluetooth printers
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (isScanning) return;

    _devices = [];
    notifyListeners();

    try {
      await BluetoothPrintPlus.startScan(timeout: timeout);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Scan error: $e');
      }
    }
  }

  /// Stop scanning
  void stopScan() {
    try {
      BluetoothPrintPlus.stopScan();
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Stop scan error: $e');
      }
    }
  }

  /// Connect to a printer
  Future<bool> connect(BluetoothDevice device) async {
    try {
      await BluetoothPrintPlus.connect(device);
      _connectedDevice = device;
      notifyListeners();

      if (kDebugMode) {
        print('✅ Connected to: ${device.name}');
      }
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Connect error: $e');
      }
      return false;
    }
  }

  /// Disconnect from printer
  Future<void> disconnect() async {
    try {
      await BluetoothPrintPlus.disconnect();
      _connectedDevice = null;
      notifyListeners();

      if (kDebugMode) {
        print('🔌 Disconnected');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Disconnect error: $e');
      }
    }
  }

  /// Print a transaction receipt using ESC/POS commands
  Future<bool> printReceipt({
    required Transaction transaction,
    String shopName = 'MACHOS BARBERSHOP',
    String shopAddress = 'Jalan Sutisna Senjaya, No. 16,\nKota Tasikmalaya',
    String shopPhone = '087731137274',
    String cashierName = 'Superadmin',
  }) async {
    if (!isConnected) {
      if (kDebugMode) {
        print('❌ No printer connected');
      }
      return false;
    }

    _isPrinting = true;
    notifyListeners();

    try {
      // Build ESC/POS receipt
      final List<int> bytes = [];

      // Initialize printer
      bytes.addAll([0x1B, 0x40]); // ESC @ - Initialize
      bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1 - Center align

      // Shop name (bold, large)
      bytes.addAll([0x1B, 0x45, 0x01]); // Bold on
      bytes.addAll([0x1D, 0x21, 0x11]); // Double height & width
      bytes.addAll(shopName.codeUnits);
      bytes.addAll([0x0A]); // Line feed
      bytes.addAll([0x1D, 0x21, 0x00]); // Normal size
      bytes.addAll([0x1B, 0x45, 0x00]); // Bold off

      // Address & phone
      for (var line in shopAddress.split('\n')) {
        bytes.addAll(line.codeUnits);
        bytes.addAll([0x0A]);
      }
      bytes.addAll(shopPhone.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      // Separator line
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      // Transaction info (left align)
      bytes.addAll([0x1B, 0x61, 0x00]); // Left align
      bytes.addAll('No: ${transaction.kodeTransaksi}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('Kasir: $cashierName'.codeUnits);
      bytes.addAll([0x0A]);
      bytes.addAll('MultiPos'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      // Separator
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      // Items
      for (var item in transaction.items) {
        bytes.addAll(item.namaProduk.codeUnits);
        bytes.addAll([0x0A]);
        final priceStr = '${item.jumlah} x ${_formatPrice(item.hargaSatuan)}';
        final subtotalStr = _formatPrice(item.subtotal);
        final spaces = 32 - priceStr.length - subtotalStr.length;
        bytes.addAll(priceStr.codeUnits);
        bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20));
        bytes.addAll(subtotalStr.codeUnits);
        bytes.addAll([0x0A]);
      }
      bytes.addAll([0x0A]);

      // Separator
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      // Totals
      _addTotalLine(bytes, 'SUBTOTAL', transaction.totalHarga);
      _addTotalLine(bytes, 'TOTAL', transaction.totalHarga);
      bytes.addAll([0x0A]);
      bytes.addAll('--------------------------------'.codeUnits);
      bytes.addAll([0x0A, 0x0A]);

      _addTotalLine(bytes, 'BAYAR', transaction.totalBayar);
      _addTotalLine(bytes, 'KEMBALI', transaction.totalKembalian);
      bytes.addAll([0x0A, 0x0A]);

      // Footer (center)
      bytes.addAll([0x1B, 0x61, 0x01]); // Center
      bytes.addAll('Terima Kasih'.codeUnits);
      bytes.addAll([0x0A, 0x0A, 0x0A, 0x0A]); // Extra line feeds

      // Cut paper (if printer supports)
      bytes.addAll([0x1D, 0x56, 0x00]); // GS V - Cut

      // Send to printer
      await BluetoothPrintPlus.write(Uint8List.fromList(bytes));

      if (kDebugMode) {
        print('🖨️ Receipt printed: ${transaction.kodeTransaksi}');
      }

      _isPrinting = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Print error: $e');
      }
      _isPrinting = false;
      notifyListeners();
      return false;
    }
  }

  void _addTotalLine(List<int> bytes, String label, double value) {
    final valueStr = 'Rp ${_formatPrice(value)}';
    final spaces = 32 - label.length - valueStr.length;
    bytes.addAll(label.codeUnits);
    bytes.addAll(List.filled(spaces > 0 ? spaces : 1, 0x20));
    bytes.addAll(valueStr.codeUnits);
    bytes.addAll([0x0A]);
  }

  String _formatPrice(double price) {
    return NumberFormat('#,###', 'id_ID').format(price).replaceAll(',', '.');
  }

  @override
  void dispose() {
    _scanResultsSubscription?.cancel();
    _connectStateSubscription?.cancel();
    super.dispose();
  }
}
