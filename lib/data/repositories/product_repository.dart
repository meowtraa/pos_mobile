/// Product Repository
/// Handles product data operations with Firebase Realtime Database
library;

import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;

import '../../core/firebase/firebase_service.dart';
import '../models/product.dart';
import '../models/category.dart';

class ProductRepository {
  static ProductRepository? _instance;
  final FirebaseService _firebase = FirebaseService.instance;

  ProductRepository._();

  static ProductRepository get instance {
    _instance ??= ProductRepository._();
    return _instance!;
  }

  /// Get the products path (master_products is an array in Firebase)
  String get _productsPath => 'master_products';

  /// Get the categories path
  String get _categoriesPath => 'master_kategori';

  /// Get all products
  Future<List<Product>> getProducts() async {
    try {
      final snapshot = await _firebase.get(_productsPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      // Firebase array: [null, {product1}, {product2}, ...]
      final data = snapshot.value as List<dynamic>;
      final products = <Product>[];

      for (var i = 0; i < data.length; i++) {
        if (data[i] != null) {
          products.add(Product.fromJson(Map<String, dynamic>.from(data[i])));
        }
      }

      return products;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get products failed: $e');
      }
      return [];
    }
  }

  /// Get products by category ID
  Future<List<Product>> getProductsByCategory(int kategoriId) async {
    final products = await getProducts();
    return products.where((p) => p.kategoriId == kategoriId).toList();
  }

  /// Get a single product by ID
  Future<Product?> getProduct(int id) async {
    try {
      final snapshot = await _firebase.get('$_productsPath/$id');

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return Product.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get product failed: $e');
      }
      return null;
    }
  }

  /// Listen to products in realtime
  Stream<List<Product>> watchProducts() {
    return _firebase.onValue(_productsPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Product>[];
      }

      final data = event.snapshot.value as List<dynamic>;
      final products = <Product>[];

      for (var i = 0; i < data.length; i++) {
        if (data[i] != null) {
          products.add(Product.fromJson(Map<String, dynamic>.from(data[i])));
        }
      }

      return products;
    });
  }

  /// Update product stock
  Future<bool> updateStock(int productId, int newStock) async {
    try {
      await _firebase.update('$_productsPath/$productId', {'stok': newStock});
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Update stock failed: $e');
      }
      return false;
    }
  }

  /// Decrease stock (for transactions) - only for products, not services
  Future<bool> decreaseStock(int productId, int quantity) async {
    try {
      final product = await getProduct(productId);
      if (product == null || product.isService) return true; // Skip for services

      final newStock = product.stok - quantity;
      if (newStock < 0) return false; // Not enough stock

      return await updateStock(productId, newStock);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Decrease stock failed: $e');
      }
      return false;
    }
  }

  // ==================== CATEGORIES ====================

  /// Get all categories
  Future<List<Category>> getCategories() async {
    try {
      final snapshot = await _firebase.get(_categoriesPath);

      if (!snapshot.exists || snapshot.value == null) {
        return [];
      }

      // Firebase array: [null, {category1}, {category2}, ...]
      final data = snapshot.value as List<dynamic>;
      final categories = <Category>[];

      for (var i = 0; i < data.length; i++) {
        if (data[i] != null) {
          categories.add(Category.fromJson(Map<String, dynamic>.from(data[i])));
        }
      }

      return categories;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get categories failed: $e');
      }
      return [];
    }
  }

  /// Listen to categories in realtime
  Stream<List<Category>> watchCategories() {
    return _firebase.onValue(_categoriesPath).map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) {
        return <Category>[];
      }

      final data = event.snapshot.value as List<dynamic>;
      final categories = <Category>[];

      for (var i = 0; i < data.length; i++) {
        if (data[i] != null) {
          categories.add(Category.fromJson(Map<String, dynamic>.from(data[i])));
        }
      }

      return categories;
    });
  }

  /// Get category by ID
  Future<Category?> getCategory(int id) async {
    try {
      final snapshot = await _firebase.get('$_categoriesPath/$id');

      if (!snapshot.exists || snapshot.value == null) {
        return null;
      }

      return Category.fromJson(Map<String, dynamic>.from(snapshot.value as Map));
    } catch (e) {
      if (kDebugMode) {
        print('❌ Get category failed: $e');
      }
      return null;
    }
  }
}
