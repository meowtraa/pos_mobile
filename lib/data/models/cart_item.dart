import 'product.dart';

/// Cart Item Model
/// Represents an item in the shopping cart
class CartItem {
  final Product product;
  final int quantity;
  final String? employeeId;
  final String? employeeName;

  const CartItem({required this.product, this.quantity = 1, this.employeeId, this.employeeName});

  /// Calculate total price for this item
  double get totalPrice => product.price * quantity;

  /// Copy with new values
  CartItem copyWith({Product? product, int? quantity, String? employeeId, String? employeeName}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
    );
  }
}
