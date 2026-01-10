import 'package:flutter/material.dart';

import '../../../../data/models/cart_item.dart';
import '../../../../data/models/staff.dart';

/// Cart Item Card Widget
/// Displays an item in the cart with quantity control
class CartItemCard extends StatelessWidget {
  final CartItem item;
  final List<Staff> staffs;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<Staff> onStaffChanged;
  final VoidCallback onRemove;

  const CartItemCard({
    super.key,
    required this.item,
    required this.staffs,
    required this.onQuantityChanged,
    required this.onStaffChanged,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: colorScheme.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row - Name and Remove Button
          Row(
            children: [
              Expanded(
                child: Text(
                  item.product.name,
                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              InkWell(
                onTap: onRemove,
                borderRadius: BorderRadius.circular(4),
                child: Icon(Icons.close, size: 18, color: colorScheme.outline),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Price
          Text(
            'Rp ${_formatPrice(item.product.price)}',
            style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w500),
          ),

          const SizedBox(height: 8),

          // Staff Dropdown (for services) and Quantity
          Row(
            children: [
              // Staff Dropdown (for services)
              if (item.product.isService)
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: item.employeeId,
                        isExpanded: true,
                        isDense: true,
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurface),
                        items: staffs.map((staff) {
                          return DropdownMenuItem(
                            value: staff.id.toString(),
                            child: Text(staff.name, overflow: TextOverflow.ellipsis),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            final staff = staffs.firstWhere((s) => s.id.toString() == value);
                            onStaffChanged(staff);
                          }
                        },
                      ),
                    ),
                  ),
                )
              else
                const Spacer(),

              const SizedBox(width: 8),

              // Quantity Control
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildQuantityButton(
                      context,
                      icon: Icons.remove,
                      onTap: () => onQuantityChanged(item.quantity - 1),
                    ),
                    Container(
                      constraints: const BoxConstraints(minWidth: 24),
                      alignment: Alignment.center,
                      child: Text(
                        '${item.quantity}x',
                        style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    _buildQuantityButton(context, icon: Icons.add, onTap: () => onQuantityChanged(item.quantity + 1)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton(BuildContext context, {required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(padding: const EdgeInsets.all(6), child: Icon(icon, size: 16)),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
