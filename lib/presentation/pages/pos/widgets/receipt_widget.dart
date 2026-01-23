import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../data/models/transaction.dart';
import '../../../../data/models/transaction_item.dart';
import '../../../../data/repositories/staff_repository.dart';

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

          // Subtotal, Discount, Total
          _buildTotalRow('SUBTOTAL', _getSubtotal()),
          if (transaction.diskonMember != null && transaction.diskonMember! > 0) ...[
            const SizedBox(height: 4),
            _buildDiscountRow('DISKON MEMBER', transaction.diskonMember!, null),
          ],
          if (transaction.diskon != null && transaction.diskon! > 0) ...[
            const SizedBox(height: 4),
            _buildDiscountRow('DISKON', transaction.diskon!, transaction.kodeVoucher),
          ],
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
    // Get kapster name: first try stored name, then lookup by userId
    String? kapsterName = item.kapsterName;
    if ((kapsterName == null || kapsterName.isEmpty) && item.userId != null) {
      kapsterName = StaffRepository.instance.getKapsterNameById(item.userId);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.namaProduk,
            style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
          ),
          // Show kapster name for service items
          if (kapsterName != null && kapsterName.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                'Kapster: $kapsterName',
                style: const TextStyle(
                  fontFamily: 'Courier',
                  fontSize: 10,
                  color: Colors.black54,
                  fontStyle: FontStyle.italic,
                ),
              ),
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

  /// Calculate subtotal (before discount)
  double _getSubtotal() {
    // If subtotal is stored, use it; otherwise calculate from total + discount
    if (transaction.subtotal != null) {
      return transaction.subtotal!;
    }
    // If no subtotal stored, add back the discount to get original subtotal
    return transaction.totalHarga + (transaction.diskon ?? 0) + (transaction.diskonMember ?? 0);
  }

  /// Build discount row with voucher code
  Widget _buildDiscountRow(String label, double value, String? voucherCode) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              label,
              style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
            ),
            if (voucherCode != null && voucherCode.isNotEmpty)
              Text(
                ' ($voucherCode)',
                style: const TextStyle(fontFamily: 'Courier', fontSize: 10, color: Colors.black54),
              ),
          ],
        ),
        Text(
          '- Rp ${_formatPrice(value)}',
          style: const TextStyle(fontFamily: 'Courier', fontSize: 11, color: Colors.black87),
        ),
      ],
    );
  }
}
