import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Formatter untuk format ribuan dengan titik
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    // Hapus semua titik yang ada
    final cleanText = newValue.text.replaceAll('.', '');

    // Cek apakah valid number
    if (int.tryParse(cleanText) == null) {
      return oldValue;
    }

    // Format dengan titik ribuan
    final formatted = _formatWithDots(cleanText);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  String _formatWithDots(String value) {
    final buffer = StringBuffer();
    final length = value.length;

    for (int i = 0; i < length; i++) {
      buffer.write(value[i]);
      final remaining = length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) {
        buffer.write('.');
      }
    }

    return buffer.toString();
  }
}

/// Payment Dialog Widget
/// Shows payment form with cash input and change calculation
class PaymentDialog extends StatefulWidget {
  final double totalAmount;
  final VoidCallback onCancel;
  final Future<bool> Function(String paymentMethod, double amountReceived) onPaymentConfirmed;

  const PaymentDialog({super.key, required this.totalAmount, required this.onCancel, required this.onPaymentConfirmed});

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cashController = TextEditingController();
  double _cashReceived = 0;
  bool _isProcessing = false;

  double get _change => _cashReceived - widget.totalAmount;
  bool get _canPay => _cashReceived >= widget.totalAmount && !_isProcessing;

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _setQuickAmount(double amount) {
    _cashController.text = _formatPrice(amount);
    setState(() => _cashReceived = amount);
  }

  void _onCashChanged(String value) {
    // Hapus titik untuk parsing
    final cleanValue = value.replaceAll('.', '');
    setState(() => _cashReceived = double.tryParse(cleanValue) ?? 0);
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final success = await widget.onPaymentConfirmed('tunai', _cashReceived);

      if (success && mounted) {
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Gagal memproses pembayaran'), backgroundColor: Colors.red));
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Pembayaran Tunai', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(backgroundColor: colorScheme.surfaceContainerHighest),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Tagihan', style: theme.textTheme.bodyLarge),
                      Text(
                        'Rp ${_formatPrice(widget.totalAmount)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Cash Input
                Text('Uang Diterima', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                  enabled: !_isProcessing,
                  onChanged: _onCashChanged,
                  style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    prefixText: 'Rp  ',
                    prefixStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                    hintText: '0',
                    hintStyle: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.outline,
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),

                const SizedBox(height: 16),

                // Quick Amount
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _QuickChip('Uang Pas', () => _setQuickAmount(widget.totalAmount)),
                    _QuickChip('50.000', () => _setQuickAmount(50000)),
                    _QuickChip('100.000', () => _setQuickAmount(100000)),
                    _QuickChip('150.000', () => _setQuickAmount(150000)),
                    _QuickChip('200.000', () => _setQuickAmount(200000)),
                  ],
                ),

                const SizedBox(height: 24),

                // Change
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _change > 0
                        ? Colors.green.withOpacity(0.1) // Ada kembalian - hijau
                        : colorScheme.surfaceContainerLow, // Netral
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Kembalian', style: theme.textTheme.bodyLarge),
                      Text(
                        'Rp ${_formatPrice(_change >= 0 ? _change : 0)}',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: _change > 0
                              ? Colors
                                    .green // Ada kembalian - hijau
                              : colorScheme.onSurface, // Normal
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isProcessing ? null : widget.onCancel,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canPay ? _processPayment : null,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Proses Pembayaran'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _QuickChip(this.label, this.onTap);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
