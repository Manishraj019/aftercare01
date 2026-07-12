import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/loyalty/data/repositories/loyalty_repository.dart';
import 'package:restaurantos/features/loyalty/domain/entities/wallet_entity.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

class OrderHistoryScreen extends ConsumerStatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  ConsumerState<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _CheckoutPaymentModal extends StatefulWidget {
  final OrderEntity order;
  final VoidCallback onPaymentSuccess;

  const _CheckoutPaymentModal({required this.order, required this.onPaymentSuccess});

  @override
  State<_CheckoutPaymentModal> createState() => _CheckoutPaymentModalState();
}

class _CheckoutPaymentModalState extends State<_CheckoutPaymentModal> {
  String _selectedMethod = 'upi';
  bool _isPaying = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: const BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Complete Payment',
                style: GoogleFonts.playfairDisplaySc(
                  color: AppTheme.primaryGold,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: AppTheme.pureWhite),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Grand Total to Pay: \$${widget.order.total.toStringAsFixed(2)}',
            style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          _buildMethodTile('UPI / Google Pay / PhonePe', 'upi', Icons.qr_code_scanner_rounded),
          Divider(color: AppTheme.borderLight),
          _buildMethodTile('Credit / Debit Card', 'card', Icons.credit_card_rounded),
          Divider(color: AppTheme.borderLight),
          _buildMethodTile('Net Banking', 'net_banking', Icons.account_balance_rounded),
          Divider(color: AppTheme.borderLight),
          _buildMethodTile('Wallets', 'wallet', Icons.account_balance_wallet_rounded),
          Divider(color: AppTheme.borderLight),
          _buildMethodTile('Pay with Cash', 'cash', Icons.payments_rounded),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isPaying ? null : _processPayment,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vegGreen,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isPaying
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2))
                : Text(
                    'CONFIRM & PAY \$${widget.order.total.toStringAsFixed(2)}',
                    style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodTile(String title, String method, IconData icon) {
    final isSelected = _selectedMethod == method;
    return InkWell(
      onTap: () => setState(() => _selectedMethod = method),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.karla(color: isSelected ? AppTheme.pureWhite : AppTheme.textMuted, fontSize: 15, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, color: AppTheme.primaryGold, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _processPayment() async {
    setState(() => _isPaying = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pop(context);
      widget.onPaymentSuccess();
    }
  }
}

class _FeedbackDialog extends StatefulWidget {
  final OrderEntity order;
  final double coinsEarned;
  final VoidCallback onSubmit;

  const _FeedbackDialog({required this.order, required this.coinsEarned, required this.onSubmit});

  @override
  State<_FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<_FeedbackDialog> {
  int _foodRating = 5;
  int _restaurantRating = 5;
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgDarkPanel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.celebration, color: AppTheme.primaryGold, size: 48),
            const SizedBox(height: 16),
            Text(
              'Thank You!',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplaySc(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Your payment was successful. We hope you enjoyed your dining experience!',
              textAlign: TextAlign.center,
              style: GoogleFonts.karla(color: AppTheme.textLight, fontSize: 14),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.vegGreen.withOpacity(0.1),
                border: Border.all(color: AppTheme.vegGreen.withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, color: AppTheme.vegGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Loyalty Points: +${widget.coinsEarned.toInt()} SuperCoins Credited!',
                    style: GoogleFonts.karla(color: AppTheme.vegGreen, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text('Rate the Food', style: GoogleFonts.karla(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRatingBar(true),
            const SizedBox(height: 16),
            Text('Rate the Restaurant Service', style: GoogleFonts.karla(color: AppTheme.pureWhite, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildRatingBar(false),
            const SizedBox(height: 16),
            TextField(
              controller: _commentController,
              style: GoogleFonts.karla(color: AppTheme.pureWhite),
              maxLines: 2,
              decoration: InputDecoration(
                hintText: 'Share any extra comments...',
                hintStyle: GoogleFonts.karla(color: AppTheme.textMuted),
                filled: true,
                fillColor: AppTheme.bgDarkCharcoal,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppTheme.borderLight)),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onSubmit();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('SUBMIT FEEDBACK', style: GoogleFonts.karla(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(bool isFood) {
    final currentVal = isFood ? _foodRating : _restaurantRating;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starNum = index + 1;
        return IconButton(
          icon: Icon(
            starNum <= currentVal ? Icons.star : Icons.star_border,
            color: AppTheme.primaryGold,
            size: 32,
          ),
          onPressed: () {
            setState(() {
              if (isFood) {
                _foodRating = starNum;
              } else {
                _restaurantRating = starNum;
              }
            });
          },
        );
      }),
    );
  }
}

class _OrderHistoryScreenState extends ConsumerState<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    ApiOrderRepository.addListener(_onOrdersChanged);
  }

  @override
  void dispose() {
    ApiOrderRepository.removeListener(_onOrdersChanged);
    super.dispose();
  }

  void _onOrdersChanged() {
    if (mounted) {
      ref.read(orderHistoryViewModelProvider.notifier).fetchOrders();
    }
  }

  void _showPaymentModal(BuildContext context, OrderEntity order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CheckoutPaymentModal(
        order: order,
        onPaymentSuccess: () {
          // Calculate loyalty points
          final config = ref.read(loyaltyConfigProvider);
          final campaigns = ref.read(loyaltyCampaignsProvider);
          final double activeMultiplier = campaigns.where((c) => c.isActive).fold(1.0, (prev, c) => prev * c.multiplier);
          final double coinsEarned = (order.total / config.earnRate) * activeMultiplier;

          // Update order status/paymentStatus in repository
          final repo = ref.read(orderRepositoryProvider);
          repo.placeOrder(order.copyWith(paymentStatus: 'paid', coinsEarned: coinsEarned));
          
          final loyaltyRepo = ref.read(loyaltyRepositoryProvider);
          final authState = ref.read(authViewModelProvider);
          if (authState is Authenticated && coinsEarned > 0) {
            loyaltyRepo.addTransaction(
              authState.user.uid,
              WalletTransaction(
                id: 'tx_earn_${DateTime.now().millisecondsSinceEpoch}',
                amount: coinsEarned,
                type: 'earn',
                description: 'Earned ${coinsEarned.toInt()} SuperCoins from Order #${order.id.replaceAll('ord_', '').toUpperCase()} (Paid \$${order.total.toStringAsFixed(2)})',
                createdAt: DateTime.now(),
                restaurantName: 'Gourmet Bistro',
                orderId: order.id,
              ),
            );
          }

          // Show Feedback Dialog
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => _FeedbackDialog(
              order: order,
              coinsEarned: coinsEarned,
              onSubmit: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Feedback submitted. Invoice saved to payment history!', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                    backgroundColor: AppTheme.vegGreen,
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersState = ref.watch(orderHistoryViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text(
          'My Orders',
          style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        backgroundColor: AppTheme.bgDeepBurgundy,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.primaryGold),
          onPressed: () => context.go('/customer'),
        ),
      ),
      body: ordersState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryGold)),
        error: (err, _) => Center(child: Text('Error: $err', style: GoogleFonts.karla(color: Colors.white))),
        data: (orders) {
          // Filter active unpaid vs. past paid orders
          final activeOrders = orders.where((o) => o.paymentStatus == 'unpaid').toList();
          final pastOrders = orders.where((o) => o.paymentStatus == 'paid').toList();

          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.receipt_long, size: 64, color: AppTheme.textMuted),
                  const SizedBox(height: 16),
                  Text(
                    'No orders placed yet',
                    style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 18),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              if (activeOrders.isNotEmpty) ...[
                Text(
                  'ACTIVE ORDERS',
                  style: GoogleFonts.spaceMono(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ...activeOrders.map((order) => _buildActiveOrderCard(context, order)),
                const SizedBox(height: 32),
              ],
              if (pastOrders.isNotEmpty) ...[
                Text(
                  'PAST ORDERS & INVOICES',
                  style: GoogleFonts.spaceMono(color: AppTheme.textMuted, fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1),
                ),
                const SizedBox(height: 12),
                ...pastOrders.map((order) => _buildPastOrderCard(context, order)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildActiveOrderCard(BuildContext context, OrderEntity order) {
    final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    final isServed = order.status == 'Served';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isServed ? AppTheme.vegGreen.withOpacity(0.3) : AppTheme.borderLight, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '#${order.id.replaceAll('ord_', '').toUpperCase()}',
                      style: GoogleFonts.spaceMono(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      'STATUS: ${order.status}',
                      style: GoogleFonts.karla(color: isServed ? AppTheme.vegGreen : AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      order.tableNumber != null ? 'Table Number: ${order.tableNumber}' : 'Takeaway / Delivery',
                      style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13),
                    ),
                    Text(
                      '\$${order.total.toStringAsFixed(2)}',
                      style: GoogleFonts.karla(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  itemsSummary,
                  style: GoogleFonts.karla(color: AppTheme.textLight, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (isServed) ...[
            _buildInvoiceReceipt(order),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: ElevatedButton.icon(
                onPressed: () => _showPaymentModal(context, order),
                icon: const Icon(Icons.payment),
                label: const Text('PROCEED TO PAYMENT'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.vegGreen,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ] else ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: OutlinedButton.icon(
                onPressed: () => context.go('/customer/orders/track/${order.id}'),
                icon: const Icon(Icons.track_changes),
                label: const Text('TRACK LIVE ORDER'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppTheme.primaryGold,
                  side: const BorderSide(color: AppTheme.primaryGold),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPastOrderCard(BuildContext context, OrderEntity order) {
    final itemsSummary = order.items.map((i) => '${i.quantity}x ${i.name}').join(', ');
    final dateStr = DateFormat('MMM dd, yyyy • hh:mm a').format(order.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkPanel.withOpacity(0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderLight.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '#${order.id.replaceAll('ord_', '').toUpperCase()}',
                style: GoogleFonts.spaceMono(color: AppTheme.pureWhite, fontSize: 14, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.vegGreen.withOpacity(0.15), borderRadius: BorderRadius.circular(6)),
                child: Text('PAID', style: GoogleFonts.karla(color: AppTheme.vegGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(itemsSummary, style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(dateStr, style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 12)),
              Text(
                '\$${order.total.toStringAsFixed(2)}',
                style: GoogleFonts.karla(color: AppTheme.primaryGold, fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppTheme.borderLight),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading Invoice INV-${order.id.replaceAll('ord_', '')}.pdf to your device...', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                        backgroundColor: AppTheme.vegGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('Invoice PDF'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryGold,
                  ),
                ),
              ),
              Expanded(
                child: TextButton.icon(
                  onPressed: () {
                    // Reorder item: populate cart and redirect to cart
                    ref.read(cartViewModelProvider.notifier).setCartItems(order.items);
                    context.go('/customer/cart');
                  },
                  icon: const Icon(Icons.replay_rounded, size: 18),
                  label: const Text('Reorder'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.pureWhite,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceReceipt(OrderEntity order) {
    // 5% GST and 5% Service Tax simulated
    final double subtotal = order.subtotal;
    final double gst = subtotal * 0.05;
    final double serviceTax = subtotal * 0.05;
    final double total = subtotal + gst + serviceTax - order.discount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.bgDarkCharcoal,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('TAX INVOICE', style: GoogleFonts.spaceMono(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.bold)),
              Text('INV-${order.id.replaceAll('ord_', '').toUpperCase()}', style: GoogleFonts.spaceMono(color: AppTheme.primaryGold, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 12),
          ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 6.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('${item.quantity}x ${item.name}', style: GoogleFonts.karla(color: AppTheme.textLight, fontSize: 13)),
                    Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 13)),
                  ],
                ),
              )),
          const Divider(color: AppTheme.borderLight, height: 24),
          _receiptRow('Subtotal', '\$${subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _receiptRow('GST (5%)', '+\$${gst.toStringAsFixed(2)}'),
          const SizedBox(height: 4),
          _receiptRow('Service Tax (5%)', '+\$${serviceTax.toStringAsFixed(2)}'),
          if (order.discount > 0) ...[
            const SizedBox(height: 4),
            _receiptRow('Discount Applied', '-\$${order.discount.toStringAsFixed(2)}', isDiscount: true),
          ],
          const Divider(color: AppTheme.borderLight, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Grand Total', style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 15, fontWeight: FontWeight.bold)),
              Text('\$${total.toStringAsFixed(2)}', style: GoogleFonts.karla(color: AppTheme.primaryGold, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receiptRow(String label, String value, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13)),
        Text(value, style: GoogleFonts.karla(color: isDiscount ? AppTheme.vegGreen : AppTheme.textLight, fontSize: 13)),
      ],
    );
  }
}
