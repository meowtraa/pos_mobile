import 'package:flutter/material.dart';

import '../../../../data/models/cart_item.dart';
import '../../../../data/models/staff.dart';
import 'cart_item_card.dart';

/// Cart Panel Widget
/// Minimalist right side panel showing cart items and checkout
/// Note: Voucher functionality has been moved to PaymentDialog
class CartPanel extends StatelessWidget {
  final List<CartItem> items;
  final List<Staff> staffs;
  final double total;
  final VoidCallback onReset;
  final VoidCallback onCheckout;
  final void Function(String productId, int quantity) onQuantityChanged;
  final void Function(String productId, Staff staff) onStaffChanged;
  final void Function(String productId) onRemoveItem;

  const CartPanel({
    super.key,
    required this.items,
    required this.staffs,
    required this.total,
    required this.onReset,
    required this.onCheckout,
    required this.onQuantityChanged,
    required this.onStaffChanged,
    required this.onRemoveItem,
  });

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
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
                if (items.isNotEmpty)
                  TextButton(
                    onPressed: onReset,
                    style: TextButton.styleFrom(foregroundColor: colorScheme.error),
                    child: const Text('Reset'),
                  ),
              ],
            ),
          ),

          Divider(height: 1, color: colorScheme.outlineVariant.withOpacity(0.5)),

          // Cart Items
          Expanded(
            child: items.isEmpty
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
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      // Use uniqueId for service items, productId for products
                      final itemId = item.uniqueId ?? item.product.id.toString();
                      return CartItemCard(
                        item: item,
                        staffs: staffs,
                        onQuantityChanged: (qty) => onQuantityChanged(itemId, qty),
                        onStaffChanged: (staff) => onStaffChanged(itemId, staff),
                        onRemove: () => onRemoveItem(itemId),
                      );
                    },
                  ),
          ),

          // Footer - Total & Checkout
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2)),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      'Rp ${_formatPrice(total)}',
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
                    onPressed: items.isEmpty ? null : onCheckout,
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
}
