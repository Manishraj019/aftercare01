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
        backgroundColor: const Color(0xFFF8F9FA),
        appBar: _buildAppBar(context, cartNotifier, isEmpty: true),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 20)
                  ],
                ),
                child: const Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
              ),
              const SizedBox(height: 32),
              Text('Your cart is empty',
                  style: GoogleFonts.karla(
                    color: Colors.black87, fontSize: 24, fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 48),
                child: Text(
                  'Looks like you haven\'t added any gourmet dishes yet.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.karla(color: Colors.grey[600], fontSize: 16),
                ),
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: () => context.pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('BROWSE MENU', style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F5),
      appBar: _buildAppBar(context, cartNotifier),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 120),
        child: Column(
          children: [
            // Cart Items
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: ListView.separated(
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                padding: const EdgeInsets.all(16),
                itemCount: cartItems.length,
                separatorBuilder: (context, index) => Divider(height: 32, color: Colors.grey[200]),
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
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))
                ],
              ),
              child: _BillCard(cartNotifier: cartNotifier),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Grand Total', style: GoogleFonts.karla(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Text('\$${cartNotifier.total.toStringAsFixed(2)}', style: GoogleFonts.karla(color: Colors.black87, fontSize: 22, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  key: const Key('checkoutButton'),
                  onPressed: () => context.push('/customer/checkout'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('PROCEED TO CHECKOUT', style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    ],
                  ),
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
      title: Text('Your Order', style: GoogleFonts.karla(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
      centerTitle: true,
      backgroundColor: Colors.white,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.black87),
      actions: isEmpty
          ? null
          : [
              IconButton(
                key: const Key('clearCartButton'),
                icon: const Icon(Icons.delete_outline_rounded, color: Colors.black54),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('Clear Cart?', style: GoogleFonts.karla(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
                      content: Text('Are you sure you want to remove all items from your cart?', style: GoogleFonts.karla(color: Colors.black54, fontSize: 16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text('CANCEL', style: GoogleFonts.karla(color: Colors.black54, fontWeight: FontWeight.bold)),
                        ),
                        TextButton(
                          onPressed: () {
                            cartNotifier.clearCart();
                            Navigator.pop(context);
                          },
                          child: Text('CLEAR', style: GoogleFonts.karla(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
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
    final parts = item.itemId.toString().split('_');
    final baseId = parts.length >= 4 ? parts.sublist(0, parts.length - 3).join('_') : item.itemId;
    debugPrint("DEBUG CART ITEM ID: ${item.itemId}, BASE ID: $baseId");
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Name & price
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name,
                  style: GoogleFonts.karla(
                    color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
              if (item.spiceLevel != null || (item.addOns != null && item.addOns!.isNotEmpty) || item.notes != null) ...[
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (item.spiceLevel != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Spice: ${item.spiceLevel}',
                          style: GoogleFonts.karla(color: Colors.orange[800], fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    if (item.addOns != null)
                      ...item.addOns!.map((addon) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              addon,
                              style: GoogleFonts.karla(color: Colors.green[800], fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          )),
                  ],
                ),
                if (item.notes != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Notes: "${item.notes}"',
                    style: GoogleFonts.karla(color: Colors.grey[600], fontSize: 12, fontStyle: FontStyle.italic),
                  ),
                ],
              ],
              const SizedBox(height: 6),
              Text('\$${item.price.toStringAsFixed(2)} each',
                  style: GoogleFonts.karla(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Stepper or Locked Status
        if (item.status != 'Waiting') ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.nonVegRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.nonVegRed.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.lock, size: 14, color: AppTheme.nonVegRed),
                const SizedBox(width: 4),
                Text(
                  '${item.status} (${item.quantity})',
                  style: GoogleFonts.karla(color: AppTheme.nonVegRed, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ] else ...[
          // Swiggy style clean stepper
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFDE9E9), // subtle tint of primary gold/red
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  key: Key('dec_$baseId'),
                  onTap: onDecrement,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Icon(Icons.remove, size: 16, color: AppTheme.primaryGold),
                  ),
                ),
                Text('${item.quantity}', style: GoogleFonts.karla(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 14)),
                InkWell(
                  key: Key('inc_$baseId'),
                  onTap: onIncrement,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Icon(Icons.add, size: 16, color: AppTheme.primaryGold),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(width: 16),
        // Item Total
        SizedBox(
          width: 60,
          child: Text(
            '\$${(item.price * item.quantity).toStringAsFixed(2)}',
            textAlign: TextAlign.right,
            style: GoogleFonts.karla(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.receipt_long, color: Colors.black87, size: 20),
              const SizedBox(width: 8),
              Text('Bill Details',
                  style: GoogleFonts.karla(
                    color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
            ],
          ),
          const SizedBox(height: 16),
          _billRow('Item Total', '\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _billRow('Taxes & Charges', '\$${cartNotifier.tax.toStringAsFixed(2)}'),
          const SizedBox(height: 12),
          _billRow('Delivery Partner Fee', '\$${cartNotifier.deliveryFee.toStringAsFixed(2)}'),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Divider(color: Colors.grey[300], thickness: 1), 
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total',
                  style: GoogleFonts.karla(
                    color: Colors.black87, fontSize: 16, fontWeight: FontWeight.bold,
                  )),
              Text('\$${cartNotifier.total.toStringAsFixed(2)}',
                  style: GoogleFonts.karla(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
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
        Text(label, style: GoogleFonts.karla(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
        Text(value, style: GoogleFonts.karla(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
