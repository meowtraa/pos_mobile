import 'package:flutter/material.dart';

import '../../../../data/models/cart_item.dart';
import '../../../../data/models/staff.dart';
import 'cart_item_card.dart';

/// Cart Panel Widget
/// Minimalist right side panel showing cart items and checkout
class CartPanel extends StatefulWidget {
  final List<CartItem> items;
  final List<Staff> staffs;
  final double subtotal;
  final double discountValue;
  final double total;
  final bool couponApplied;
  final String? couponError;
  final double discountPercent;
  final VoidCallback onReset;
  final VoidCallback onCheckout;
  final void Function(String productId, int quantity) onQuantityChanged;
  final void Function(String productId, Staff staff) onStaffChanged;
  final void Function(String productId) onRemoveItem;
  final void Function(String code) onApplyCoupon;
  final VoidCallback onRemoveCoupon;

  const CartPanel({
    super.key,
    required this.items,
    required this.staffs,
    required this.subtotal,
    required this.discountValue,
    required this.total,
    required this.couponApplied,
    this.couponError,
    this.discountPercent = 0,
    required this.onReset,
    required this.onCheckout,
    required this.onQuantityChanged,
    required this.onStaffChanged,
    required this.onRemoveItem,
    required this.onApplyCoupon,
    required this.onRemoveCoupon,
  });

  @override
  State<CartPanel> createState() => _CartPanelState();
}

class _CartPanelState extends State<CartPanel> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: 340,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(-2, 0))],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Keranjang', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                if (widget.items.isNotEmpty)
                  TextButton(
                    onPressed: widget.onReset,
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    child: const Text('Reset'),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),

          // Cart Items
          Expanded(
            child: widget.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 56, color: colorScheme.outline.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text(
                          'Keranjang kosong',
                          style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = widget.items[index];
                      return CartItemCard(
                        item: item,
                        staffs: widget.staffs,
                        onQuantityChanged: (qty) => widget.onQuantityChanged(item.product.id.toString(), qty),
                        onStaffChanged: (staff) => widget.onStaffChanged(item.product.id.toString(), staff),
                        onRemove: () => widget.onRemoveItem(item.product.id.toString()),
                      );
                    },
                  ),
          ),

          // Footer - Coupon, Subtotal, Discount, Total, Checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Column(
              children: [
                // TODO: Enable coupon feature later
                // Coupon Input - COMMENTED OUT
                // Row(
                //   children: [
                //     Expanded(
                //       child: TextField(
                //         controller: _couponController,
                //         enabled: !widget.couponApplied,
                //         textCapitalization: TextCapitalization.characters,
                //         decoration: InputDecoration(
                //           hintText: 'Kode Kupon',
                //           prefixIcon: const Icon(Icons.discount_outlined, size: 20),
                //           contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                //           border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                //           isDense: true,
                //         ),
                //         style: theme.textTheme.bodyMedium,
                //       ),
                //     ),
                //     const SizedBox(width: 8),
                //     if (widget.couponApplied)
                //       IconButton.filled(
                //         onPressed: () {
                //           _couponController.clear();
                //           widget.onRemoveCoupon();
                //         },
                //         style: IconButton.styleFrom(
                //           backgroundColor: colorScheme.errorContainer,
                //           foregroundColor: colorScheme.error,
                //         ),
                //         icon: const Icon(Icons.close, size: 20),
                //       )
                //     else
                //       FilledButton(
                //         onPressed: widget.items.isEmpty ? null : () => widget.onApplyCoupon(_couponController.text),
                //         style: FilledButton.styleFrom(
                //           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                //         ),
                //         child: const Text('Pakai'),
                //       ),
                //   ],
                // ),
                //
                // // Coupon Error or Success
                // if (widget.couponError != null)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 8),
                //     child: Row(
                //       children: [
                //         Icon(Icons.error_outline, size: 16, color: colorScheme.error),
                //         const SizedBox(width: 4),
                //         Text(widget.couponError!, style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.error)),
                //       ],
                //     ),
                //   ),
                // if (widget.couponApplied)
                //   Padding(
                //     padding: const EdgeInsets.only(top: 8),
                //     child: Row(
                //       children: [
                //         Icon(Icons.check_circle, size: 16, color: colorScheme.primary),
                //         const SizedBox(width: 4),
                //         Text(
                //           'Kupon berhasil diterapkan!',
                //           style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                //         ),
                //       ],
                //     ),
                //   ),
                //
                // const SizedBox(height: 16),

                // Subtotal - commented out since each item now shows subtotal
                // Uncomment when PPN is implemented
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //   children: [
                //     Text('Subtotal', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
                //     Text(
                //       'Rp ${_formatPrice(widget.subtotal)}',
                //       style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                //     ),
                //   ],
                // ),

                // Discount Row (if applicable)
                if (widget.discountValue > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text('Diskon', style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary)),
                          if (widget.discountPercent > 0)
                            Text(
                              ' (${widget.discountPercent.toInt()}%)',
                              style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.primary),
                            ),
                        ],
                      ),
                      Text(
                        '- Rp ${_formatPrice(widget.discountValue)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 12),

                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${_formatPrice(widget.total)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Checkout Button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: widget.items.isEmpty ? null : widget.onCheckout,
                    icon: const Icon(Icons.payments_outlined),
                    label: const Text('Bayar Sekarang'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
