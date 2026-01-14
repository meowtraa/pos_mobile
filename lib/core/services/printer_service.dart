import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/models/transaction.dart';

/// Printer Service
/// Handles Bluetooth thermal printer connection and printing
class PrinterService extends ChangeNotifier {
  static PrinterService? _instance;

  List<BluetoothInfo> _devices = [];
  BluetoothInfo? _connectedDevice;
  bool _isPrinting = false;
  bool _isScanning = false;

  // Persistence
  SharedPreferences? _prefs;
  static const String _keyLastPrinterAddress = 'last_printer_address';
  static const String _keyLastPrinterName = 'last_printer_name';

  // ESC/POS Commands
  static const List<int> _escAlignLeft = [27, 97, 0];
  static const List<int> _escAlignCenter = [27, 97, 1];
  static const List<int> _escLineSpacing24 = [27, 51, 3]; // Compact line spacing
  static const List<int> _escLineSpacing30 = [27, 51, 12]; // Normal line spacing

  // Scan status tracking
  String? _lastScanMessage;
  bool _lastScanSuccess = false;

  PrinterService._();

  static PrinterService get instance {
    _instance ??= PrinterService._();
    return _instance!;
  }

  // Getters
  BluetoothInfo? get connectedDevice => _connectedDevice;
  bool get isConnected => _connectedDevice != null;
  bool get isScanning => _isScanning;
  bool get isPrinting => _isPrinting;
  List<BluetoothInfo> get devices => _devices;
  bool get isBluetoothOn => true; // Checked during scan
  String? get lastScanMessage => _lastScanMessage;
  bool get lastScanSuccess => _lastScanSuccess;

  /// Initialize printer service and try to auto-reconnect
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _tryAutoReconnect();
  }

  Future<void> _tryAutoReconnect() async {
    final address = _prefs?.getString(_keyLastPrinterAddress);
    final name = _prefs?.getString(_keyLastPrinterName);

    if (address != null && name != null) {
      if (kDebugMode) {
        print('🔗 Trying to auto-reconnect to: $name ($address)');
      }

      // Try to scan and find the saved device
      if (kDebugMode) {
        print('🔖 Saved printer info found. Will attempt to reconnect when scanned.');
      }
    }
  }

  /// Start scanning for Bluetooth printers
  Future<void> startScan() async {
    if (_isScanning) {
      if (kDebugMode) print('⚠️ Already scanning, skipping');
      return;
    }

    _isScanning = true;
    notifyListeners();

    if (kDebugMode) {
      print('\n🔍 === Starting Bluetooth Printer Scan ===');
    }

    // Check if Bluetooth is enabled
    final bluetoothState = await PrintBluetoothThermal.bluetoothEnabled;
    if (kDebugMode) {
      print('📱 Bluetooth enabled: $bluetoothState');
    }

    if (!bluetoothState) {
      if (kDebugMode) {
        print('❌ Bluetooth is OFF! Please enable Bluetooth.');
      }
      _isScanning = false;
      notifyListeners();
      return;
    }

    // Check permissions on Android
    if (Platform.isAndroid) {
      if (kDebugMode) {
        print('🔐 Checking Android permissions...');
      }

      final scanStatus = await Permission.bluetoothScan.request();
      final connectStatus = await Permission.bluetoothConnect.request();
      final locationStatus = await Permission.location.request();

      if (kDebugMode) {
        print('  - Bluetooth Scan: $scanStatus');
        print('  - Bluetooth Connect: $connectStatus');
        print('  - Location: $locationStatus');
      }

      if (scanStatus.isDenied || connectStatus.isDenied || locationStatus.isDenied) {
        if (kDebugMode) {
          print('❌ Permissions denied!');
        }
        if (scanStatus.isPermanentlyDenied || connectStatus.isPermanentlyDenied) {
          if (kDebugMode) {
            print('⚠️ Permissions permanently denied, opening settings...');
          }
          openAppSettings();
        }
        _isScanning = false;
        notifyListeners();
        return;
      }

      if (kDebugMode) {
        print('✅ All permissions granted');
      }
    }

    try {
      if (kDebugMode) {
        print('🔎 Scanning for paired and available devices...');
      }

      // Get paired devices (MUCH more reliable!)
      final List<BluetoothInfo> pairedDevices = await PrintBluetoothThermal.pairedBluetooths;

      if (kDebugMode) {
        print('📱 Found ${pairedDevices.length} paired devices');
        for (var device in pairedDevices) {
          print('   - ${device.name} (${device.macAdress})');
        }
      }

      _devices = pairedDevices;

      // Set scan result message
      if (_devices.isEmpty) {
        _lastScanSuccess = false;
        _lastScanMessage =
            'Tidak ada printer ditemukan.\nSilakan pair printer dari Android Bluetooth Settings terlebih dahulu.';
        if (kDebugMode) {
          print('❌ No paired devices found!');
          print('💡 Please pair printer in Android Settings first');
        }
      } else {
        _lastScanSuccess = true;
        _lastScanMessage = 'Ditemukan ${_devices.length} printer';
        if (kDebugMode) {
          print('✅ Scan completed successfully');
        }
      }

      _isScanning = false;
      notifyListeners();
    } catch (e) {
      if (kDebugMode) {
        print('❌ Scan error: $e');
      }
      _isScanning = false;
      notifyListeners();
    }
  }

  /// Stop scanning (not needed for this library, but keep for API compatibility)
  Future<void> stopScan() async {
    _isScanning = false;
    notifyListeners();
  }

  /// Connect to a printer
  Future<bool> connect(BluetoothInfo device) async {
    try {
      if (kDebugMode) {
        print('\n🔌 Connecting to: ${device.name} (${device.macAdress})');
      }

      final result = await PrintBluetoothThermal.connect(macPrinterAddress: device.macAdress);

      if (result) {
        _connectedDevice = device;

        // Save printer info for auto-reconnect
        await _prefs?.setString(_keyLastPrinterAddress, device.macAdress);
        await _prefs?.setString(_keyLastPrinterName, device.name);

        notifyListeners();

        if (kDebugMode) {
          print('✅ Connected to: ${device.name}');
          print('💾 Saved printer for auto-reconnect');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ Connection failed');
        }
        return false;
      }
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
      await PrintBluetoothThermal.disconnect;
      _connectedDevice = null;

      // Clear saved printer
      await _prefs?.remove(_keyLastPrinterAddress);
      await _prefs?.remove(_keyLastPrinterName);

      notifyListeners();

      if (kDebugMode) {
        print('🔌 Disconnected');
        print('🗑️ Cleared saved printer');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Disconnect error: $e');
      }
    }
  }

  /// Test print - using writeString API
  Future<bool> testPrint() async {
    if (!isConnected) {
      if (kDebugMode) {
        print('❌ No printer connected');
      }
      return false;
    }

    try {
      if (kDebugMode) {
        print('\n🧪 === Test Print ===');
      }

      // Use writeString as per documentation
      final enter = '\n';
      await PrintBluetoothThermal.writeBytes(enter.codeUnits);

      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 2, text: "TEST PRINT$enter"));

      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "Hello from POS!$enter"));

      await PrintBluetoothThermal.writeString(
        printText: PrintTextSize(size: 1, text: "Printer Working!$enter$enter$enter"),
      );

      if (kDebugMode) {
        print('🖨️ Test print sent successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Test print error: $e');
      }
      return false;
    }
  }

  /// Print a transaction receipt
  /// [paperSize] can be 58 (mm) or 80 (mm).
  Future<bool> printReceipt({
    required Transaction transaction,
    String shopName = 'MACHOS BARBERSHOP',
    String shopAddress = 'Jalan Sutisna Senjaya, No. 16,\nKota Tasikmalaya',
    String shopPhone = '087731137274',
    String cashierName = 'Superadmin',
    int paperSize = 58,
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
      final enter = '\n';

      // Configuration based on paper size
      // 58mm -> usually 32 chars (normal) or 42 chars (condensed)
      // User request: "Dash line doesn't reach end", implies 32 is too short.
      final int maxChars = paperSize == 58 ? 42 : 48;

      // Effective printable width
      final int effectiveWidth = maxChars;
      final String indent = '';

      // Helpers
      Future<void> printLine(String text, {int size = 1}) async {
        // Ensure left alignment for lines
        await PrintBluetoothThermal.writeBytes(_escAlignLeft);
        await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: size, text: "$text$enter"),
        );
      }

      Future<void> printCentered(String text, {int size = 1}) async {
        // Use native center alignment
        await PrintBluetoothThermal.writeBytes(_escAlignCenter);
        await PrintBluetoothThermal.writeString(
          printText: PrintTextSize(size: size, text: "$text$enter"),
        );
        // Reset to left
        await PrintBluetoothThermal.writeBytes(_escAlignLeft);
      }

      // --- START PRINTING ---

      // Set compact line spacing
      await PrintBluetoothThermal.writeBytes(_escLineSpacing24);

      // Header
      // Shop Name: Use Size 2 if it fits (short name or 80mm), else Size 1
      // 58mm max chars for Size 2 is approx 16. "MACHOS BARBERSHOP" is 17 chars.
      // So for 58mm, it might wrap or cut if Size 2.
      // Let's use Size 2 only if paperSize is 80 OR text length is small.
      int shopNameSize = 1;
      if (paperSize == 80 || shopName.length <= 16) {
        shopNameSize = 2;
      }

      await printCentered(shopName, size: shopNameSize);

      // Address (CENTER)
      for (var line in shopAddress.split('\n')) {
        await printCentered(line);
      }

      // Phone (CENTER)
      await printCentered(shopPhone);

      // Dashed line
      await printLine('-' * effectiveWidth);

      // Transaction info
      // Reverted to printLine as per user request (not centered)
      await printLine("No: ${transaction.kodeTransaksi}");
      await printLine("Tgl: ${DateFormat('dd/MM/yyyy HH:mm').format(transaction.createdAt)}");
      await printLine("Kasir: $cashierName");
      await printLine("MultiPos");

      // Dashed line
      await printLine('-' * effectiveWidth);

      // Items
      for (var item in transaction.items) {
        // Product name
        await printLine(item.namaProduk);

        // Quantity x Price = Subtotal
        final qtyPrice = '${item.jumlah} x ${_formatPrice(item.hargaSatuan)}';
        final subtotal = _formatPrice(item.subtotal);

        // Calculate spaces specifically for this line
        final spacesCount = effectiveWidth - qtyPrice.length - subtotal.length;
        final spaces = ' ' * (spacesCount > 0 ? spacesCount : 1);

        final line = qtyPrice + spaces + subtotal;
        await printLine(line);
      }

      // Dashed line
      await printLine('-' * effectiveWidth);

      // Subtotal & Total
      await _printTotalLine('SUBTOTAL', transaction.totalHarga, effectiveWidth, indent);
      await _printTotalLine('TOTAL', transaction.totalHarga, effectiveWidth, indent);

      // Dashed line
      await printLine('-' * effectiveWidth);

      // Payment
      await _printTotalLine('BAYAR', transaction.totalBayar, effectiveWidth, indent);
      await _printTotalLine('KEMBALI', transaction.totalKembalian, effectiveWidth, indent);

      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "$enter"));

      // Footer (CENTER)
      await printCentered('Terima Kasih');
      await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "$enter$enter$enter"));

      // Reset to normal line spacing
      await PrintBluetoothThermal.writeBytes(_escLineSpacing30);

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

  /// Helper for printing "Label ... Value" lines
  Future<void> _printTotalLine(String label, double value, int width, String indent) async {
    final valueStr = 'Rp ${_formatPrice(value)}';
    final spacesCount = width - label.length - valueStr.length;
    final spaces = ' ' * (spacesCount > 0 ? spacesCount : 1);
    final line = label + spaces + valueStr;

    // Ensure left align
    await PrintBluetoothThermal.writeBytes(_escAlignLeft);
    await PrintBluetoothThermal.writeString(printText: PrintTextSize(size: 1, text: "$line\n"));
  }

  String _formatPrice(double price) {
    return NumberFormat('#,###', 'id_ID').format(price).replaceAll(',', '.');
  }
}
