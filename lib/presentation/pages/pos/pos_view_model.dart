import 'dart:async';
import 'package:flutter/foundation.dart' hide Category;

import '../../../data/models/cart_item.dart';
import '../../../data/models/category.dart';
import '../../../data/models/product.dart';
import '../../../data/models/staff.dart';
import '../../../data/models/transaction.dart' as model;
import '../../../data/models/transaction_item.dart';
import '../../../data/models/voucher.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/staff_repository.dart';
import '../../../data/repositories/transaction_repository.dart';
import '../../../data/repositories/voucher_repository.dart';
import '../../providers/base_view_model.dart';

/// POS View Model
/// Handles business logic for POS Page with Firebase integration
class POSViewModel extends BaseViewModel {
  // Repositories
  final ProductRepository _productRepo = ProductRepository.instance;
  final StaffRepository _staffRepo = StaffRepository.instance;
  final TransactionRepository _transactionRepo = TransactionRepository.instance;
  final VoucherRepository _voucherRepo = VoucherRepository.instance;

  // Stream subscriptions
  StreamSubscription? _productsSubscription;
  StreamSubscription? _staffSubscription;

  // State
  List<Product> _products = [];
  List<Category> _categories = [];
  List<Staff> _staffs = [];
  List<CartItem> _cartItems = [];
  String _selectedCategoryId = '0'; // '0' = all
  String _searchQuery = '';
  bool _isLoading = true;
  String? _error;

  // Coupon/Voucher State
  String _couponCode = '';
  double _discountAmount = 0;
  double _discountPercent = 0;
  double _maxPotongan = 0;
  String? _couponError;
  bool _couponApplied = false;
  bool _isApplyingCoupon = false;
  Voucher? _appliedVoucher;

  // Getters
  List<Product> get products => _products;
  List<CartItem> get cartItems => _cartItems;
  String get selectedCategoryId => _selectedCategoryId;
  String get searchQuery => _searchQuery;
  List<Staff> get staffs => _staffs;
  List<Category> get categories => _categories;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Coupon Getters
  String get couponCode => _couponCode;
  double get discountAmount => _discountAmount;
  double get discountPercent => _discountPercent;
  String? get couponError => _couponError;
  bool get couponApplied => _couponApplied;
  bool get isApplyingCoupon => _isApplyingCoupon;
  Voucher? get appliedVoucher => _appliedVoucher;
  bool get hasDiscount => _discountAmount > 0 || _discountPercent > 0;

  /// Get filtered products based on category and search
  List<Product> get filteredProducts {
    return _products.where((product) {
      // Filter by category (0 = all)
      final matchesCategory = _selectedCategoryId == '0' || product.kategoriId.toString() == _selectedCategoryId;

      // Filter by search query
      final matchesSearch =
          _searchQuery.isEmpty || product.namaProduk.toLowerCase().contains(_searchQuery.toLowerCase());

      return matchesCategory && matchesSearch;
    }).toList();
  }

  /// Calculate subtotal
  double get subtotal {
    return _cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  }

  /// Calculate discount value (respects maxPotongan for percentage discount)
  double get discountValue {
    if (_discountPercent > 0) {
      final calculated = subtotal * (_discountPercent / 100);
      // Apply max discount limit if specified
      if (_maxPotongan > 0 && calculated > _maxPotongan) {
        return _maxPotongan;
      }
      return calculated;
    }
    return _discountAmount;
  }

  /// Calculate total with discount
  double get total {
    final discounted = subtotal - discountValue;
    return discounted > 0 ? discounted : 0;
  }

  /// Check if cart is empty
  bool get isCartEmpty => _cartItems.isEmpty;

  /// Get cart item count
  int get cartItemCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);

  /// Initialize with Firebase data
  POSViewModel() {
    _initialize();
  }

  /// Initialize data from Firebase
  Future<void> _initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load categories first
      _categories = await _productRepo.getCategories();

      // Add "Semua" category at the beginning if not exists
      if (_categories.isEmpty || _categories.first.id != 0) {
        _categories.insert(0, const Category(id: 0, namaKategori: 'Semua', tipe: CategoryType.jasa));
      }

      // Subscribe to products stream
      _productsSubscription = _productRepo.watchProducts().listen((products) {
        _products = products;
        notifyListeners();
        if (kDebugMode) {
          print('🔄 Products updated: ${products.length} items');
        }
      });

      // Subscribe to staffs stream
      _staffSubscription = _staffRepo.watchKapsters().listen((staffs) {
        _staffs = staffs;
        notifyListeners();
        if (kDebugMode) {
          print('🔄 Staffs updated: ${staffs.length} kapsters');
        }
      });

      // Initial load
      _products = await _productRepo.getProducts();
      _staffs = await _staffRepo.getKapsters();

      _isLoading = false;
      _error = null;

      if (kDebugMode) {
        print('✅ POS initialized: ${_products.length} products, ${_staffs.length} staffs');
      }
    } catch (e) {
      _isLoading = false;
      _error = 'Gagal memuat data: $e';
      if (kDebugMode) {
        print('❌ POS initialization failed: $e');
      }
    }

    notifyListeners();
  }

  /// Refresh data from Firebase
  Future<void> refresh() async {
    await _initialize();
  }

  /// Set selected category
  void setCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    notifyListeners();
  }

  /// Set search query
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// Check if product can be added to cart
  bool canAddToCart(Product product) {
    // Service items can always be added
    if (product.isService) return true;

    // Check if product has stock
    if (product.stok <= 0) return false;

    // Check if adding more would exceed stock
    final existingItem = _cartItems.firstWhere(
      (item) => item.product.id == product.id,
      orElse: () => CartItem(product: product, quantity: 0),
    );

    return existingItem.quantity < product.stok;
  }

  /// Add product to cart
  /// Returns true if added successfully, false if out of stock
  bool addToCart(Product product) {
    // Check if product can be added
    if (!canAddToCart(product)) {
      if (kDebugMode) {
        print('⚠️ Cannot add ${product.namaProduk}: out of stock or limit reached');
      }
      return false;
    }

    final existingIndex = _cartItems.indexWhere((item) => item.product.id == product.id);

    if (existingIndex != -1) {
      // Update quantity if already in cart
      final existing = _cartItems[existingIndex];
      _cartItems[existingIndex] = existing.copyWith(quantity: existing.quantity + 1);
    } else {
      // Add new item with default staff for services
      _cartItems.add(
        CartItem(
          product: product,
          quantity: 1,
          employeeId: product.isService && _staffs.isNotEmpty ? _staffs.first.id.toString() : null,
          employeeName: product.isService && _staffs.isNotEmpty ? _staffs.first.name : null,
        ),
      );
    }
    notifyListeners();
    return true;
  }

  /// Remove item from cart
  void removeFromCart(String productId) {
    _cartItems.removeWhere((item) => item.product.id.toString() == productId);
    notifyListeners();
  }

  /// Update item quantity
  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }

    final index = _cartItems.indexWhere((item) => item.product.id.toString() == productId);

    if (index != -1) {
      final item = _cartItems[index];

      // Limit quantity to available stock for non-service items
      int finalQuantity = quantity;
      if (!item.product.isService && quantity > item.product.stok) {
        finalQuantity = item.product.stok;
        if (kDebugMode) {
          print('⚠️ Quantity limited to stock: ${item.product.stok}');
        }
      }

      _cartItems[index] = _cartItems[index].copyWith(quantity: finalQuantity);
      notifyListeners();
    }
  }

  /// Update staff for cart item
  void updateEmployee(String productId, Staff staff) {
    final index = _cartItems.indexWhere((item) => item.product.id.toString() == productId);

    if (index != -1) {
      _cartItems[index] = _cartItems[index].copyWith(employeeId: staff.id.toString(), employeeName: staff.name);
      notifyListeners();
    }
  }

  /// Apply coupon/voucher code from Firebase
  Future<void> applyCoupon(String code) async {
    if (code.isEmpty) {
      _couponError = 'Masukkan kode voucher';
      notifyListeners();
      return;
    }

    _couponCode = code.toUpperCase().trim();
    _couponError = null;
    _isApplyingCoupon = true;
    notifyListeners();

    try {
      // Validate voucher from Firebase
      final result = await _voucherRepo.validateVoucher(_couponCode, subtotal);

      if (result.voucher != null) {
        final voucher = result.voucher!;
        _appliedVoucher = voucher;

        if (voucher.tipe == VoucherType.persen) {
          _discountPercent = voucher.nilai;
          _discountAmount = 0;
          _maxPotongan = voucher.maxPotongan;
        } else {
          _discountAmount = voucher.nilai > subtotal ? subtotal : voucher.nilai;
          _discountPercent = 0;
          _maxPotongan = 0;
        }
        _couponApplied = true;
        _couponError = null;

        if (kDebugMode) {
          print('🎫 Voucher applied: ${voucher.kode} (${voucher.tipe}, ${voucher.nilai})');
        }
      } else {
        _couponError = result.error ?? 'Kode voucher tidak valid';
        _discountAmount = 0;
        _discountPercent = 0;
        _maxPotongan = 0;
        _couponApplied = false;
        _appliedVoucher = null;
      }
    } catch (e) {
      _couponError = 'Gagal memvalidasi voucher';
      _discountAmount = 0;
      _discountPercent = 0;
      _maxPotongan = 0;
      _couponApplied = false;
      _appliedVoucher = null;

      if (kDebugMode) {
        print('❌ Apply voucher failed: $e');
      }
    }

    _isApplyingCoupon = false;
    notifyListeners();
  }

  /// Remove applied coupon/voucher
  void removeCoupon() {
    _couponCode = '';
    _discountAmount = 0;
    _discountPercent = 0;
    _maxPotongan = 0;
    _couponError = null;
    _couponApplied = false;
    _appliedVoucher = null;
    notifyListeners();
  }

  /// Reset cart
  void resetCart() {
    _cartItems.clear();
    removeCoupon();
    notifyListeners();
  }

  /// Process checkout - create transaction in Firebase
  /// Returns the created Transaction on success, null on failure
  Future<model.Transaction?> checkout({
    required String paymentMethod,
    required double amountReceived,
    required int userId,
  }) async {
    try {
      // Generate transaction code (UUID-based, guaranteed unique)
      final kodeTransaksi = _transactionRepo.generateTransactionCode();

      // Create transaction items
      final items = _cartItems
          .map(
            (cartItem) => TransactionItem(
              produkId: cartItem.product.id,
              namaProduk: cartItem.product.namaProduk,
              hargaSatuan: cartItem.product.harga,
              jumlah: cartItem.quantity,
              subtotal: cartItem.totalPrice,
              userId: cartItem.employeeId != null ? int.tryParse(cartItem.employeeId!) : null,
            ),
          )
          .toList();

      // Create transaction
      final transaction = model.Transaction(
        kodeTransaksi: kodeTransaksi,
        items: items,
        totalHarga: total,
        totalBayar: amountReceived,
        totalKembalian: amountReceived - total,
        metodePembayaran: paymentMethod,
        statusTransaksi: model.TransactionStatus.selesai,
        userId: userId,
        createdAt: DateTime.now(),
      );

      // Save to Firebase
      await _transactionRepo.createTransaction(transaction);

      // Update stock for products
      for (var item in _cartItems) {
        if (!item.product.isService) {
          await _productRepo.decreaseStock(item.product.id, item.quantity);
        }
      }

      // Decrease voucher quota if voucher was applied
      if (_appliedVoucher != null && _couponApplied) {
        await _voucherRepo.useVoucher(_appliedVoucher!.kode);
      }

      // Reset cart
      resetCart();

      if (kDebugMode) {
        print('✅ Transaction created: $kodeTransaksi');
      }

      return transaction;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Checkout failed: $e');
      }
      return null;
    }
  }

  @override
  void dispose() {
    _productsSubscription?.cancel();
    _staffSubscription?.cancel();
    super.dispose();
  }
}
