import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// TODO: Enable when ready
// import '../../providers/theme_view_model.dart';
import '../../../core/services/session_service.dart';
import '../../../data/models/transaction.dart';
import '../../widgets/connectivity_banner.dart';
import '../../widgets/sync_indicator.dart';
import 'pos_view_model.dart';
import 'widgets/cart_panel.dart';
import 'widgets/category_chips.dart';
import 'widgets/payment_dialog.dart';
import 'widgets/product_card.dart';
import 'widgets/receipt_dialog.dart';
import 'widgets/success_dialog.dart';

/// POS Page
/// Main Point of Sale screen
class POSPage extends StatefulWidget {
  const POSPage({super.key});

  @override
  State<POSPage> createState() => _POSPageState();
}

class _POSPageState extends State<POSPage> {
  // Store last transaction for receipt
  Transaction? _lastTransaction;

  /// Show payment dialog
  void _showPaymentDialog(BuildContext context, POSViewModel viewModel, double total) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PaymentDialog(
        totalAmount: total,
        onCancel: () => Navigator.pop(dialogContext),
        onPaymentConfirmed: (paymentMethod, amountReceived) async {
          // Get userId from session
          final userId = int.tryParse(SessionService.instance.userId ?? '1') ?? 1;

          // Call checkout to create transaction in Firebase
          final transaction = await viewModel.checkout(
            paymentMethod: paymentMethod,
            amountReceived: amountReceived,
            userId: userId,
          );

          if (transaction != null) {
            _lastTransaction = transaction;
            // NOTE: PaymentDialog already handles Navigator.pop() in _processPayment()
            // So we just show success dialog after a short delay
            Future.delayed(const Duration(milliseconds: 150), () {
              if (context.mounted) {
                _showSuccessDialog(context, transaction);
              }
            });
          }

          return transaction != null;
        },
      ),
    );
  }

  /// Show success dialog
  void _showSuccessDialog(BuildContext context, Transaction transaction) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SuccessDialog(
        onPrintReceipt: () async {
          Navigator.pop(dialogContext);
          // Wait a moment for dialog to close
          await Future.delayed(const Duration(milliseconds: 100));
          // Show receipt dialog using main context
          if (context.mounted) {
            ReceiptDialog.show(context, transaction: transaction);
          }
        },
        onNewTransaction: () {
          Navigator.pop(dialogContext);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Main Content with Connectivity Banner
          ConnectivityBanner(
            child: SafeArea(
              child: Row(
                children: [
                  // Left - Products Section
                  Expanded(child: _ProductsSection()),
                  // Right - Cart Panel
                  Consumer<POSViewModel>(
                    builder: (context, viewModel, _) {
                      return CartPanel(
                        items: viewModel.cartItems,
                        staffs: viewModel.staffs,
                        subtotal: viewModel.subtotal,
                        discountValue: viewModel.discountValue,
                        total: viewModel.total,
                        couponApplied: viewModel.couponApplied,
                        couponError: viewModel.couponError,
                        discountPercent: viewModel.discountPercent,
                        onReset: viewModel.resetCart,
                        onCheckout: () => _showPaymentDialog(context, viewModel, viewModel.total),
                        onQuantityChanged: viewModel.updateQuantity,
                        onStaffChanged: (productId, staff) {
                          viewModel.updateEmployee(productId, staff);
                        },
                        onRemoveItem: viewModel.removeFromCart,
                        onApplyCoupon: viewModel.applyCoupon,
                        onRemoveCoupon: viewModel.removeCoupon,
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          // Floating Sync Indicator
          const SyncIndicator(),
        ],
      ),
    );
  }
}

/// Products Section Widget
class _ProductsSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Consumer<POSViewModel>(
      builder: (context, viewModel, _) {
        return Column(
          children: [
            // Header - Logo, Search and Category Filter
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(bottom: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and Search Row
                  Row(
                    children: [
                      // Logo
                      Image.asset(
                        'assets/images/logo.PNG',
                        height: 40,
                        errorBuilder: (_, __, ___) => Row(
                          children: [
                            Icon(Icons.content_cut, color: colorScheme.primary, size: 28),
                            const SizedBox(width: 8),
                            Text(
                              'BarberPOS',
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      // Search Field
                      Expanded(
                        child: TextField(
                          onChanged: viewModel.setSearchQuery,
                          decoration: InputDecoration(
                            hintText: 'Cari produk...',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceContainerHighest,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Profile Menu
                      PopupMenuButton<String>(
                        offset: const Offset(0, 50),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: colorScheme.primary,
                                child: const Icon(Icons.person, size: 18, color: Colors.white),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    SessionService.instance.userName ?? 'User',
                                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                                  ),
                                  Text(
                                    SessionService.instance.userRole ?? 'Staff',
                                    style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 4),
                              Icon(Icons.arrow_drop_down, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                        onSelected: (value) {
                          if (value == 'profile') {
                            Navigator.pushNamed(context, '/profile');
                          } else if (value == 'logout') {
                            showDialog(
                              context: context,
                              builder: (dialogContext) => AlertDialog(
                                title: const Text('Logout'),
                                content: const Text('Apakah Anda yakin ingin keluar?'),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Batal')),
                                  FilledButton(
                                    onPressed: () async {
                                      Navigator.pop(dialogContext);
                                      // Clear session
                                      await SessionService.instance.clearSession();
                                      if (context.mounted) {
                                        Navigator.pushReplacementNamed(context, '/login');
                                      }
                                    },
                                    child: const Text('Logout'),
                                  ),
                                ],
                              ),
                            );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            enabled: false,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: colorScheme.primary,
                                      child: const Icon(Icons.person, size: 28, color: Colors.white),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          SessionService.instance.userName ?? 'User',
                                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          SessionService.instance.userEmail ?? '',
                                          style: theme.textTheme.bodySmall?.copyWith(
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 'profile',
                            child: Row(
                              children: [
                                Icon(Icons.person_outline, color: colorScheme.onSurface),
                                const SizedBox(width: 12),
                                const Text('Profil Saya'),
                              ],
                            ),
                          ),

                          // TODO: Enable when ready
                          // PopupMenuItem(
                          //   value: 'theme',
                          //   child: Consumer<ThemeViewModel>(
                          //     builder: (context, themeVM, _) {
                          //       return Row(
                          //         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          //         children: [
                          //           Row(
                          //             children: [
                          //               Icon(
                          //                 themeVM.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          //                 color: colorScheme.onSurface,
                          //               ),
                          //               const SizedBox(width: 12),
                          //               const Text('Mode Gelap'),
                          //             ],
                          //           ),
                          //           Switch(value: themeVM.isDarkMode, onChanged: (_) => themeVM.toggleTheme()),
                          //         ],
                          //       );
                          //     },
                          //   ),
                          // ),
                          const PopupMenuDivider(),
                          PopupMenuItem(
                            value: 'logout',
                            child: Row(
                              children: [
                                Icon(Icons.logout, color: colorScheme.error),
                                const SizedBox(width: 12),
                                Text('Logout', style: TextStyle(color: colorScheme.error)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Category Chips
                  CategoryChips(
                    selectedCategoryId: viewModel.selectedCategoryId,
                    onCategoryChanged: viewModel.setCategory,
                  ),
                ],
              ),
            ),

            // Products Grid with Pull to Refresh
            Expanded(
              child: RefreshIndicator(
                onRefresh: viewModel.refresh,
                child: viewModel.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : viewModel.filteredProducts.isEmpty
                    ? ListView(
                        // Need scrollable for RefreshIndicator to work on empty
                        children: [
                          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                          Icon(Icons.inventory_2_outlined, size: 64, color: colorScheme.outline),
                          const SizedBox(height: 16),
                          Center(
                            child: Text(
                              viewModel.error ?? 'Tidak ada produk',
                              style: theme.textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
                            ),
                          ),
                        ],
                      )
                    : GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 220,
                          childAspectRatio: 0.8, // Increased to reduce empty space
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: viewModel.filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = viewModel.filteredProducts[index];
                          final canAdd = viewModel.canAddToCart(product);
                          return ProductCard(
                            product: product,
                            isDisabled: !canAdd,
                            onTap: () {
                              final added = viewModel.addToCart(product);
                              if (!added && context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.namaProduk} stok habis!'),
                                    backgroundColor: Colors.orange,
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              }
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        );
      },
    );
  }
}
