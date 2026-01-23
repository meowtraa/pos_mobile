import 'package:flutter/material.dart';

import '../../../../data/models/cart_item.dart';
import '../../../../data/models/staff.dart';

/// Cart Item Card Widget
/// Displays an item in the cart with quantity control and subtotal
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
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.close, size: 20, color: colorScheme.error),
                ),
              ),
            ],
          ),

          const SizedBox(height: 4),

          // Price per unit + Satuan
          Text(
            'Rp ${_formatPrice(item.product.price)} / ${item.product.satuan}',
            style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
          ),

          const SizedBox(height: 12),

          // Staff Dropdown (for services) and Quantity
          Row(
            children: [
              // Staff Dropdown (for services) - styled like +/- buttons
              if (item.product.isService)
                Expanded(
                  child: Container(
                    height: 44, // Same height as quantity buttons
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: item.employeeId,
                        isExpanded: true,
                        isDense: false,
                        menuMaxHeight: 300, // Scrollable if many items
                        menuWidth: 250, // WIDER popup menu
                        icon: Icon(Icons.keyboard_arrow_down, color: colorScheme.primary),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                        dropdownColor: colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        // Selected value display (in button) - can truncate
                        selectedItemBuilder: (context) {
                          return staffs.map((staff) {
                            return Container(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                staff.name,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                              ),
                            );
                          }).toList();
                        },
                        // Menu items - show FULL name, wider
                        items: staffs.map((staff) {
                          return DropdownMenuItem<String>(
                            value: staff.id.toString(),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Text(staff.name, style: theme.textTheme.bodyMedium),
                            ),
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

              // Only show spacer if not a service (service already has dropdown that's Expanded)
              if (!item.product.isService) const SizedBox(width: 12),

              // Quantity Control - Only show for NON-SERVICE items
              // Service items are always qty=1, click again to add another with different kapster
              if (!item.product.isService)
                Container(
                  height: 44, // Same height as dropdown
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Minus Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onQuantityChanged(item.quantity - 1),
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(9)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            child: Icon(Icons.remove, size: 20, color: colorScheme.primary),
                          ),
                        ),
                      ),
                      // Quantity Display (tanpa 'x')
                      Container(
                        constraints: const BoxConstraints(minWidth: 32),
                        alignment: Alignment.center,
                        child: Text(
                          '${item.quantity}',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      // Plus Button
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => onQuantityChanged(item.quantity + 1),
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(9)),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            alignment: Alignment.center,
                            child: Icon(Icons.add, size: 20, color: colorScheme.primary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Subtotal per Item
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(
                'Rp ${_formatPrice(item.totalPrice)}',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
