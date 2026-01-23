import 'product.dart';

/// Cart Item Model
/// Represents an item in the shopping cart
class CartItem {
  final Product product;
  final int quantity;
  final String? employeeId;
  final String? employeeName;

  /// Unique ID for distinguishing service items with same product but different instances
  /// This allows multiple service items with different kapsters in one transaction
  final String? uniqueId;

  const CartItem({required this.product, this.quantity = 1, this.employeeId, this.employeeName, this.uniqueId});

  /// Calculate total price for this item
  double get totalPrice => product.price * quantity;

  /// Copy with new values
  CartItem copyWith({Product? product, int? quantity, String? employeeId, String? employeeName, String? uniqueId}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      uniqueId: uniqueId ?? this.uniqueId,
    );
  }
}
