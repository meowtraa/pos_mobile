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

/// Formatter untuk mengubah text menjadi uppercase
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(text: newValue.text.toUpperCase(), selection: newValue.selection);
  }
}

/// Payment Dialog Widget - New Design V2
/// Layout:
/// 1. Header & Total
/// 2. Row(WhatsApp, Voucher)
/// 3. Summary (Full Width)
/// 4. Payment Method
/// 5. Cash Input & Quick Amounts (if Cash)
class PaymentDialog extends StatefulWidget {
  final double subtotal;
  final double discountValue;
  final double totalAmount;
  final bool couponApplied;
  final String? couponError;
  final String? appliedCouponCode;
  final VoidCallback onCancel;
  final Future<void> Function(String code) onApplyCoupon;
  final VoidCallback onRemoveCoupon;
  final Future<bool> Function(String paymentMethod, double amountReceived, String? whatsapp) onPaymentConfirmed;
  final bool isApplyingCoupon;

  const PaymentDialog({
    super.key,
    required this.subtotal,
    required this.discountValue,
    required this.totalAmount,
    required this.couponApplied,
    this.couponError,
    this.appliedCouponCode,
    required this.onCancel,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
    required this.onPaymentConfirmed,
    this.isApplyingCoupon = false,
  });

  @override
  State<PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<PaymentDialog> {
  final _cashController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _voucherController = TextEditingController();

  double _cashReceived = 0;
  bool _isProcessing = false;
  bool _isCashPayment = true; // true = Tunai, false = Non Tunai

  double get _change => _cashReceived - widget.totalAmount;
  bool get _canPay {
    if (_isProcessing) return false;
    if (_isCashPayment) {
      return _cashReceived >= widget.totalAmount;
    }
    return true; // Non tunai tidak perlu input cash
  }

  @override
  void initState() {
    super.initState();
    // Pre-fill voucher code if already applied
    if (widget.appliedCouponCode != null) {
      _voucherController.text = widget.appliedCouponCode!;
    }
  }

  @override
  void dispose() {
    _cashController.dispose();
    _whatsappController.dispose();
    _voucherController.dispose();
    super.dispose();
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }

  void _onCashChanged(String value) {
    final cleanValue = value.replaceAll('.', '');
    setState(() => _cashReceived = double.tryParse(cleanValue) ?? 0);
  }

  void _setQuickAmount(double amount) {
    _cashController.text = _formatPrice(amount);
    setState(() => _cashReceived = amount);
  }

  Future<void> _processPayment() async {
    setState(() => _isProcessing = true);

    try {
      final paymentMethod = _isCashPayment ? 'Tunai' : 'Non Tunai';
      final amountReceived = _isCashPayment ? _cashReceived : widget.totalAmount;
      final whatsapp = _whatsappController.text.trim().isNotEmpty ? _whatsappController.text.trim() : null;

      final success = await widget.onPaymentConfirmed(paymentMethod, amountReceived, whatsapp);

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
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550), // Reduced width for single column feel
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
                    Text('Pembayaran', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: _isProcessing ? null : widget.onCancel,
                      icon: const Icon(Icons.close),
                      style: IconButton.styleFrom(backgroundColor: colorScheme.surfaceContainerHighest),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Total Tagihan - Centered
                Center(
                  child: Column(
                    children: [
                      Text(
                        'Total Tagihan',
                        style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Rp ${_formatPrice(widget.totalAmount)}',
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary, // Blue color like design
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Row 1: WhatsApp (Optional) & Voucher Input
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // WhatsApp
                    Expanded(
                      flex: 4,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'WhatsApp (Opsional)',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _whatsappController,
                            keyboardType: TextInputType.phone,
                            enabled: !_isProcessing,
                            decoration: InputDecoration(
                              hintText: '08xxxxxx',
                              prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Voucher
                    Expanded(
                      flex: 6,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Kode Voucher',
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _voucherController,
                                  enabled: !widget.couponApplied && !widget.isApplyingCoupon && !_isProcessing,
                                  textCapitalization: TextCapitalization.characters,
                                  inputFormatters: [UpperCaseTextFormatter()],
                                  decoration: InputDecoration(
                                    hintText: 'Kode',
                                    prefixIcon: const Icon(Icons.local_offer_outlined, size: 20),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                    filled: widget.couponApplied,
                                    fillColor: widget.couponApplied ? colorScheme.surfaceContainerHighest : null,
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              if (widget.isApplyingCoupon)
                                const SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: Padding(
                                    padding: EdgeInsets.all(12),
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              else if (widget.couponApplied)
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Color(0xFFFFCDD2), // Pink background (Red 100)
                                  ),
                                  child: IconButton(
                                    onPressed: _isProcessing
                                        ? null
                                        : () {
                                            _voucherController.clear();
                                            widget.onRemoveCoupon();
                                          },
                                    icon: const Icon(Icons.close, size: 20, color: Color(0xFFD32F2F)), // Red 700
                                    splashRadius: 24,
                                  ),
                                )
                              else
                                FilledButton(
                                  onPressed: _isProcessing ? null : () => widget.onApplyCoupon(_voucherController.text),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E3A5F), // Dark blue like design
                                    minimumSize: const Size(0, 48),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Cek'),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // Voucher Message (Full Width)
                if (widget.couponError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      widget.couponError!,
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error),
                    ),
                  ),
                if (widget.couponApplied && widget.discountValue > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Voucher berhasil digunakan! Hemat Rp ${_formatPrice(widget.discountValue)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Row 2: Summary Box (Full Width)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Subtotal
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Subtotal', style: theme.textTheme.bodyMedium),
                          Text(
                            'Rp ${_formatPrice(widget.subtotal)}',
                            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                      if (widget.discountValue > 0) ...[
                        const SizedBox(height: 8),
                        // Diskon
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Diskon', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                            Text(
                              '- Rp ${_formatPrice(widget.discountValue)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      // Total Bayar
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total Bayar', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(
                            'Rp ${_formatPrice(widget.totalAmount)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Row 3: Payment Method
                Text('Metode Pembayaran', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                _AnimatedPaymentToggle(
                  isCash: _isCashPayment,
                  onChanged: (val) {
                    if (!_isProcessing) setState(() => _isCashPayment = val);
                  },
                ),

                // Row 4: Cash Input & Quick Amounts (Only if Tunai)
                if (_isCashPayment) ...[
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cash Input
                      Text('Uang Diterima', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _cashController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.digitsOnly, ThousandsSeparatorInputFormatter()],
                        enabled: !_isProcessing,
                        onChanged: _onCashChanged,
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                          prefixText: 'Rp ',
                          hintText: '0',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Quick Amounts
                      Text(
                        'Uang Pas / Nominal',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _QuickChip(
                              label: 'Uang Pas',
                              onTap: !_isProcessing ? () => _setQuickAmount(widget.totalAmount) : null,
                            ),
                            _QuickChip(label: '50.000', onTap: !_isProcessing ? () => _setQuickAmount(50000) : null),
                            _QuickChip(label: '100.000', onTap: !_isProcessing ? () => _setQuickAmount(100000) : null),
                            _QuickChip(label: '200.000', onTap: !_isProcessing ? () => _setQuickAmount(200000) : null),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Kembalian
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9), // Light green
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Kembalian', style: theme.textTheme.bodyMedium),
                        Text(
                          'Rp ${_formatPrice(_change >= 0 ? _change : 0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2E7D32), // Dark green
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Footer Buttons
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
                    const SizedBox(width: 16),
                    Expanded(
                      child: FilledButton(
                        onPressed: _canPay ? _processPayment : null,
                        style: FilledButton.styleFrom(
                          backgroundColor: colorScheme.primary,
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

/// Payment Method Selection Button
class _AnimatedPaymentToggle extends StatelessWidget {
  final bool isCash;
  final ValueChanged<bool> onChanged;

  const _AnimatedPaymentToggle({required this.isCash, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      height: 50,
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(25)),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeInOut,
                    alignment: isCash ? Alignment.centerLeft : Alignment.centerRight,
                    child: Container(
                      width: constraints.maxWidth / 2,
                      height: constraints.maxHeight,
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(21),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2)),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onChanged(true),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.account_balance_wallet_outlined,
                                  size: 20,
                                  color: isCash ? Colors.white : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Tunai',
                                  style: TextStyle(
                                    fontWeight: isCash ? FontWeight.w600 : FontWeight.w500,
                                    color: isCash ? Colors.white : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => onChanged(false),
                          behavior: HitTestBehavior.opaque,
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.credit_card_outlined,
                                  size: 20,
                                  color: !isCash ? Colors.white : colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Non Tunai',
                                  style: TextStyle(
                                    fontWeight: !isCash ? FontWeight.w600 : FontWeight.w500,
                                    color: !isCash ? Colors.white : colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _QuickChip({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label),
    );
  }
}
