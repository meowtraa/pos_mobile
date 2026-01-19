import 'package:flutter/material.dart';

import '../../../../data/models/category.dart';

/// Category Chips Widget
/// Minimalist filter chips for product categories
class CategoryChips extends StatelessWidget {
  final List<Category> categories;
  final String selectedCategoryId;
  final ValueChanged<String> onCategoryChanged;

  const CategoryChips({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategoryChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Use SingleChildScrollView to allow scrolling if many categories
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category.categoryId == selectedCategoryId;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Material(
              color: isSelected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              child: InkWell(
                onTap: () => onCategoryChanged(category.categoryId),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outlineVariant),
                  ),
                  child: Text(
                    category.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : colorScheme.onSurface,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
