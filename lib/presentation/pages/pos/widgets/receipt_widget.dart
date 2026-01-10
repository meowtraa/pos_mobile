import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/transaction.dart';
import '../../../../data/models/transaction_item.dart';

/// Receipt Widget
/// Displays a receipt with barbershop style formatting
class ReceiptWidget extends StatelessWidget {
  final Transaction transaction;
  final String shopName;
  final String shopAddress;
  final String shopPhone;
  final String cashierName;

  const ReceiptWidget({
    super.key,
    required this.transaction,
    this.shopName = 'MACHOS BARBERSHOP',
    this.shopAddress = 'Jalan Sutisna Senjaya, No. 16,\nKota Tasikmalaya',
    this.shopPhone = '087731137274',
    this.cashierName = 'Superadmin',
  });

  String _formatPrice(double price) {
    return NumberFormat('#,###', 'id_ID').format(price).replaceAll(',', '.');
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header - Shop Name
          Text(
            shopName,
            style: const TextStyle(
              fontFamily: 'Courier',
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),

          // Address
          Text(
            shopAddress,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),
          Text(
            shopPhone,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 12),
          _buildDottedLine(),
          const SizedBox(height: 12),

          // Transaction Info
          _buildInfoRow('No:', transaction.kodeTransaksi),
          _buildInfoRow('Tgl:', _formatDate(transaction.createdAt)),
          _buildInfoRow('Kasir:', cashierName),
          const Text(
            'MultiPos',
            style: TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black54),
          ),

          const SizedBox(height: 12),
          _buildDottedLine(),
          const SizedBox(height: 12),

          // Items
          ...transaction.items.map((item) => _buildItemRow(item)),

          const SizedBox(height: 12),
          _buildDottedLine(),
          const SizedBox(height: 12),

          // Subtotal
          _buildTotalRow('SUBTOTAL', transaction.totalHarga),
          const SizedBox(height: 4),
          _buildTotalRow('TOTAL', transaction.totalHarga, isBold: true),

          const SizedBox(height: 12),
          _buildDottedLine(),
          const SizedBox(height: 12),

          // Payment
          _buildTotalRow('BAYAR', transaction.totalBayar),
          const SizedBox(height: 4),
          _buildTotalRow('KEMBALI', transaction.totalKembalian),

          const SizedBox(height: 20),

          // Footer
          const Text(
            'Terima Kasih',
            style: TextStyle(fontFamily: 'Courier', fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _buildDottedLine() {
    return Row(
      children: List.generate(
        35,
        (index) => const Expanded(
          child: Text(
            '.',
            style: TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black38),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        '$label $value',
        style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
      ),
    );
  }

  Widget _buildItemRow(TransactionItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.namaProduk,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.jumlah} x ${_formatPrice(item.hargaSatuan)}',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black54),
              ),
              Text(
                _formatPrice(item.subtotal),
                style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
        Text(
          'Rp ${_formatPrice(value)}',
          style: TextStyle(
            fontFamily: 'Courier',
            fontSize: 11,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
