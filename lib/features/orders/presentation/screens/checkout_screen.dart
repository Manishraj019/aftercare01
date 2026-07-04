import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurantos/core/localization/app_localizations.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/checkout_viewmodel.dart';

import 'package:restaurantos/features/owner/presentation/widgets/fake_owner_data.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController(text: '123 Gourmet Ave, Foodtown');
  final _couponController = TextEditingController();
  String _selectedPaymentMethod = 'upi'; // Default payment
  Promotion? _appliedPromotion;
  String? _couponStatusMessage;
  bool _isCouponSuccess = false;

  @override
  void dispose() {
    _addressController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  void _applyCoupon() {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _appliedPromotion = null;
        _couponStatusMessage = null;
        _isCouponSuccess = false;
      });
      return;
    }

    try {
      final promo = FakeOwnerData.promotions.firstWhere(
        (p) => p.code.toUpperCase() == code,
      );
      if (!promo.isActive) {
        setState(() {
          _appliedPromotion = null;
          _couponStatusMessage = 'Coupon code expired or inactive.';
          _isCouponSuccess = false;
        });
      } else {
        setState(() {
          _appliedPromotion = promo;
          _couponStatusMessage = 'Applied! ${promo.discountPercent.toInt()}% off (${promo.description})';
          _isCouponSuccess = true;
        });
      }
    } catch (_) {
      setState(() {
        _appliedPromotion = null;
        _couponStatusMessage = 'Invalid coupon code.';
        _isCouponSuccess = false;
      });
    }
  }

  double _calculateDiscount(double subtotal) {
    if (_appliedPromotion == null) return 0.0;
    return subtotal * (_appliedPromotion!.discountPercent / 100);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final cartNotifier = ref.read(cartViewModelProvider.notifier);
      final discount = _calculateDiscount(cartNotifier.subtotal);
      ref.read(checkoutViewModelProvider.notifier).placeOrder(
            deliveryAddress: _addressController.text.trim(),
            paymentMethod: _selectedPaymentMethod,
            discountAmount: discount,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartNotifier = ref.read(cartViewModelProvider.notifier);
    final checkoutState = ref.watch(checkoutViewModelProvider);

    // Listen to checkout state changes
    ref.listen<CheckoutState>(checkoutViewModelProvider, (previous, next) {
      if (next is CheckoutSuccess) {
        // Reset checkout state
        ref.read(checkoutViewModelProvider.notifier).reset();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Order Placed Successfully!'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        // Redirect to Order History
        context.go('/customer/orders');
      } else if (next is CheckoutError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = checkoutState is CheckoutLoading;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('Delivery Location', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('addressField'),
                  controller: _addressController,
                  enabled: !isLoading,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    hintText: 'Enter your shipping address',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return AppLocalizations.fieldRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                const Text('Payment Method', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    ChoiceChip(
                      key: const Key('pay_upi'),
                      label: const Text('UPI / Scan'),
                      selected: _selectedPaymentMethod == 'upi',
                      onSelected: isLoading
                          ? null
                          : (selected) {
                              if (selected) setState(() => _selectedPaymentMethod = 'upi');
                            },
                    ),
                    ChoiceChip(
                      key: const Key('pay_card'),
                      label: const Text('Card'),
                      selected: _selectedPaymentMethod == 'card',
                      onSelected: isLoading
                          ? null
                          : (selected) {
                              if (selected) setState(() => _selectedPaymentMethod = 'card');
                            },
                    ),
                    ChoiceChip(
                      key: const Key('pay_wallet'),
                      label: const Text('Wallet'),
                      selected: _selectedPaymentMethod == 'wallet',
                      onSelected: isLoading
                          ? null
                          : (selected) {
                              if (selected) setState(() => _selectedPaymentMethod = 'wallet');
                            },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Have a Coupon? Section
                const Text('Have a Coupon?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const Key('couponField'),
                        controller: _couponController,
                        decoration: InputDecoration(
                          hintText: 'Enter coupon code (e.g. BISTRO20)',
                          prefixIcon: const Icon(Icons.local_offer_outlined),
                          errorText: !_isCouponSuccess && _couponStatusMessage != null ? _couponStatusMessage : null,
                          helperText: _isCouponSuccess ? null : 'Try WELCOME50 or BISTRO20',
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      key: const Key('applyCouponButton'),
                      onPressed: _applyCoupon,
                      child: const Text('Apply'),
                    ),
                  ],
                ),
                if (_isCouponSuccess && _couponStatusMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _couponStatusMessage!,
                    style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
                const SizedBox(height: 24),

                // Order Totals Summary
                Builder(
                  builder: (context) {
                    final discount = _calculateDiscount(cartNotifier.subtotal);
                    final grandTotal = (cartNotifier.total - discount).clamp(0.0, double.infinity);

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text('Bill Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Items Subtotal'),
                                    Text('\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Taxes (8%)'),
                                    Text('\$${cartNotifier.tax.toStringAsFixed(2)}'),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Delivery Fee'),
                                    Text('\$${cartNotifier.deliveryFee.toStringAsFixed(2)}'),
                                  ],
                                ),
                                if (discount > 0) ...[
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('Discount (${_appliedPromotion?.code})', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                      Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                ],
                                const Divider(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                    Text(
                                      '\$${grandTotal.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),

                        // Confirm place order button
                        ElevatedButton(
                          key: const Key('confirmOrderButton'),
                          onPressed: isLoading ? null : _submit,
                          child: isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : Text('Pay & Place Order (\$${grandTotal.toStringAsFixed(2)})'),
                        ),
                      ],
                    );
                  }
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
