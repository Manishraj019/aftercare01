import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartViewModelProvider);
    final cartNotifier = ref.read(cartViewModelProvider.notifier);

    if (cartItems.isEmpty) {
      return Scaffold(
        backgroundColor: AppTheme.bgDarkCharcoal,
        appBar: _buildAppBar(context, cartNotifier, isEmpty: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GlassContainer(
                blur: 15, opacity: 0.5,
                borderRadius: BorderRadius.circular(50),
                padding: const EdgeInsets.all(32),
                child: const Icon(Icons.shopping_cart_outlined,
                    size: 80, color: AppTheme.primaryGold),
              ),
              const SizedBox(height: 32),
              Text('Your cart is empty',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.pureWhite, fontSize: 28, fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Looks like you haven\'t added any gourmet dishes yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 16),
                ),
              ),
              const SizedBox(height: 48),
              FoodPrimaryButton(
                onPressed: () => context.pop(),
                label: 'BROWSE MENU',
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: _buildAppBar(context, cartNotifier),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // Cart Items
            GlassContainer(
              margin: const EdgeInsets.all(20),
              blur: 20, opacity: 0.8,
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(24),
                itemCount: cartItems.length,
                separatorBuilder: (context, index) => Divider(height: 32, color: AppTheme.borderLight),
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return _CartItemRow(
                    item: item,
                    onDecrement: () => cartNotifier.updateQuantity(item.itemId, -1),
                    onIncrement: () => cartNotifier.updateQuantity(item.itemId, 1),
                  );
                },
              ),
            ),

            // Bill Details Receipt
            GlassContainer(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              blur: 20, opacity: 0.8,
              child: _BillCard(cartNotifier: cartNotifier),
            ),
          ],
        ),
      ),
      bottomSheet: GlassContainer(
        blur: 30, opacity: 0.95,
        color: AppTheme.bgDarkCharcoal.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppTheme.borderLight)),
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grand Total', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
                    Text('\$${cartNotifier.total.toStringAsFixed(2)}', style: GoogleFonts.playfairDisplay(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: FoodPrimaryButton(
                  key: const Key('checkoutButton'),
                  onPressed: () => context.push('/customer/checkout'),
                  label: 'PROCEED',
                  icon: Icons.arrow_forward_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, CartViewModel cartNotifier,
      {bool isEmpty = false}) {
    return AppBar(
      title: Text('Your Cart', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 22)),
      centerTitle: true,
      backgroundColor: AppTheme.bgDeepBurgundy,
      elevation: 0,
      iconTheme: const IconThemeData(color: AppTheme.primaryGold),
      actions: isEmpty
          ? null
          : [
              IconButton(
                key: const Key('clearCartButton'),
                icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.textMuted),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppTheme.bgDarkPanel,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppTheme.borderLight)),
                      title: Text('Clear Cart?', style: GoogleFonts.playfairDisplay(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
                      content: Text('Are you sure you want to remove all items from your cart?', style: GoogleFonts.inter(color: AppTheme.textLight)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('CANCEL', style: GoogleFonts.inter(color: AppTheme.textMuted, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {
                            cartNotifier.clearCart();
                            Navigator.pop(context);
                          },
                          child: Text('CLEAR', style: GoogleFonts.inter(color: AppTheme.nonVegRed, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Clear Cart',
              ),
            ],
    );
  }
}

// ─── Cart Item Row ─────────────────────────────────────────────────
class _CartItemRow extends StatelessWidget {
  final dynamic item;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;

  const _CartItemRow({
    required this.item,
    required this.onDecrement,
    required this.onIncrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: GoogleFonts.inter(
                    color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 6),
              Text('\$${item.price.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(color: AppTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Stepper
        AddStepperButton(
          quantity: item.quantity,
          onAdd: onIncrement,
          onRemove: onDecrement,
        ),
        const SizedBox(width: 16),
        // Item Total
        SizedBox(
          width: 60,
          child: Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: GoogleFonts.inter(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

// ─── Bill Card ─────────────────────────────────────────────────────
class _BillCard extends StatelessWidget {
  final CartViewModel cartNotifier;

  const _BillCard({required this.cartNotifier});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Bill Details',
              style: GoogleFonts.playfairDisplay(
                color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold,
              )),
          const SizedBox(height: 20),
          _billRow('Item Total', '\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _billRow('Taxes & Charges', '\$${cartNotifier.tax.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _billRow('Delivery Partner Fee', '\$${cartNotifier.deliveryFee.toStringAsFixed(2)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: AppTheme.borderLight), 
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: GoogleFonts.inter(
                    color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
              Text('\$${cartNotifier.total.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _billRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14)),
        Text(value, style: GoogleFonts.inter(color: AppTheme.pureWhite, fontSize: 14, fontWeight: FontWeight.w500)),
      ],
    );
  }
}
