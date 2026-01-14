import 'package:flutter/material.dart';

import '../../../../data/models/product.dart';

/// Product Card Widget
/// Minimalist card displaying a product with image, name, price, and tag
class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isDisabled;

  const ProductCard({super.key, required this.product, required this.onTap, this.isDisabled = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDisabled
                      ? colorScheme.outlineVariant.withValues(alpha: 0.3)
                      : colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Opacity(
                opacity: isDisabled ? 0.5 : 1.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    AspectRatio(
                      aspectRatio: 1.3,
                      child: Container(
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                          child: Image.network(
                            product.imageUrl ?? '',
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Icon(Icons.image_outlined, size: 40, color: colorScheme.outline),
                          ),
                        ),
                      ),
                    ),

                    // Product Info
                    Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8), // Compact padding
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Product Name
                          Text(
                            product.name,
                            style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6), // Reduced gap
                          // Price and Tag Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // Price
                              Text(
                                'Rp ${_formatPrice(product.price)}',
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.primary,
                                ),
                              ),
                              // Tag
                              _buildTag(context),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // "Stok Habis" overlay for out of stock items
            if (isDisabled)
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.shade600, borderRadius: BorderRadius.circular(6)),
                  child: const Text(
                    'Stok Habis',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (product.isService) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Jasa',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colorScheme.primary),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(6)),
        child: Text(
          'Stok: ${product.stock}',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: colorScheme.onSurfaceVariant),
        ),
      );
    }
  }

  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.');
  }
}
