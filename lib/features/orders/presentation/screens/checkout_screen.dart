import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/localization/app_localizations.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
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
  String _selectedPaymentMethod = 'upi';
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
          _couponStatusMessage = 'Coupon expired or inactive';
          _isCouponSuccess = false;
        });
      } else {
        setState(() {
          _appliedPromotion = promo;
          _couponStatusMessage = '${promo.discountPercent.toInt()}% off applied!';
          _isCouponSuccess = true;
        });
      }
    } catch (_) {
      setState(() {
        _appliedPromotion = null;
        _couponStatusMessage = 'Invalid coupon code';
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

    ref.listen<CheckoutState>(checkoutViewModelProvider, (previous, next) {
      if (next is CheckoutSuccess) {
        ref.read(checkoutViewModelProvider.notifier).reset();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite),
                const SizedBox(width: 12),
                Text('Order Placed Successfully!', style: GoogleFonts.inter(color: AppTheme.pureWhite)),
              ],
            ),
            backgroundColor: AppTheme.vegGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        context.go('/customer/orders');
      } else if (next is CheckoutError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.inter(color: AppTheme.pureWhite)),
            backgroundColor: AppTheme.nonVegRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    final isLoading = checkoutState is CheckoutLoading;
    final discount = _calculateDiscount(cartNotifier.subtotal);
    final grandTotal = (cartNotifier.total - discount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: AppTheme.bgDeepBurgundy,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppTheme.primaryGold),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth >= 900;
            return Form(
              key: _formKey,
              child: isDesktop
                  ? _buildDesktopLayout(isLoading, grandTotal, cartNotifier, discount)
                  : _buildMobileLayout(isLoading, grandTotal, cartNotifier, discount),
            );
          },
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
                    Text('Amount to Pay', style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
                    Text('\$${grandTotal.toStringAsFixed(2)}', style: GoogleFonts.playfairDisplay(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: FoodPrimaryButton(
                  key: const Key('confirmOrderButton'),
                  onPressed: isLoading ? null : _submit,
                  label: isLoading ? 'PROCESSING...' : 'PLACE ORDER',
                  isLoading: isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isLoading, double grandTotal, CartViewModel cartNotifier, double discount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 48.0, vertical: 32.0).copyWith(bottom: 120),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 6, child: _buildLeftColumn(isLoading)),
          const SizedBox(width: 48),
          Expanded(flex: 4, child: _buildRightColumn(isLoading, grandTotal, cartNotifier, discount)),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isLoading, double grandTotal, CartViewModel cartNotifier, double discount) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0).copyWith(bottom: 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLeftColumn(isLoading),
          const SizedBox(height: 24),
          _buildRightColumn(isLoading, grandTotal, cartNotifier, discount),
        ],
      ),
    );
  }

  Widget _buildLeftColumn(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Address Section
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.location_on, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text('Delivery Address', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                key: const Key('addressField'),
                controller: _addressController,
                enabled: !isLoading,
                hintText: 'Enter your full address',
                validator: (value) => (value == null || value.isEmpty)
                    ? AppLocalizations.fieldRequired
                    : null,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Payment Section
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.payment, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text('Payment Method', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Column(
                children: [
                  _PaymentRow(
                    label: 'UPI',
                    icon: Icons.qr_code_scanner_rounded,
                    isSelected: _selectedPaymentMethod == 'upi',
                    onTap: isLoading ? null : () => setState(() => _selectedPaymentMethod = 'upi'),
                    key: const Key('pay_upi'),
                  ),
                  Divider(color: AppTheme.borderLight),
                  _PaymentRow(
                    label: 'Credit / Debit Card',
                    icon: Icons.credit_card_rounded,
                    isSelected: _selectedPaymentMethod == 'card',
                    onTap: isLoading ? null : () => setState(() => _selectedPaymentMethod = 'card'),
                    key: const Key('pay_card'),
                  ),
                  Divider(color: AppTheme.borderLight),
                  _PaymentRow(
                    label: 'Wallets',
                    icon: Icons.account_balance_wallet_rounded,
                    isSelected: _selectedPaymentMethod == 'wallet',
                    onTap: isLoading ? null : () => setState(() => _selectedPaymentMethod = 'wallet'),
                    key: const Key('pay_wallet'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(bool isLoading, double grandTotal, CartViewModel cartNotifier, double discount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Offers Section
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.local_offer, color: AppTheme.primaryGold, size: 20),
                  const SizedBox(width: 8),
                  Text('Offers & Benefits', style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildTextField(
                      key: const Key('couponField'),
                      controller: _couponController,
                      hintText: 'Enter coupon code',
                      isError: !_isCouponSuccess && _couponStatusMessage != null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    height: 52,
                    child: TextButton(
                      key: const Key('applyCouponButton'),
                      onPressed: _applyCoupon,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                        ),
                      ),
                      child: Text('APPLY', style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
              if (_couponStatusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _couponStatusMessage!,
                  style: GoogleFonts.inter(
                    color: _isCouponSuccess ? AppTheme.vegGreen : AppTheme.nonVegRed,
                    fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Bill Summary
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bill Summary',
                  style: GoogleFonts.playfairDisplay(
                    color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 20),
              _billRow('Item Total', '\$${cartNotifier.subtotal.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _billRow('Taxes & Charges', '\$${cartNotifier.tax.toStringAsFixed(2)}'),
              const SizedBox(height: 12),
              _billRow('Delivery Partner Fee', '\$${cartNotifier.deliveryFee.toStringAsFixed(2)}'),
              if (discount > 0) ...[
                const SizedBox(height: 12),
                _billRow('Discount (${_appliedPromotion?.code})',
                    '-\$${discount.toStringAsFixed(2)}',
                    color: AppTheme.primaryGold),
              ],
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
                  Text('\$${grandTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    Key? key,
    required TextEditingController controller,
    required String hintText,
    bool enabled = true,
    bool isError = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      key: key,
      controller: controller,
      enabled: enabled,
      style: GoogleFonts.inter(color: AppTheme.pureWhite, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
        filled: true,
        fillColor: AppTheme.bgDarkPanel.withValues(alpha: 0.5),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppTheme.borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: isError ? AppTheme.nonVegRed : AppTheme.primaryGold, width: 1),
        ),
      ),
      validator: validator,
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14)),
        Text(value,
            style: GoogleFonts.inter(
                color: color ?? AppTheme.pureWhite, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

// ─── Payment Row ──────────────────────────────────────────────────
class _PaymentRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback? onTap;

  const _PaymentRow({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgDarkPanel.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.borderLight)
              ),
              child: Icon(icon, color: AppTheme.primaryGold, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.inter(
                    color: AppTheme.pureWhite,
                    fontSize: 15, fontWeight: FontWeight.w500,
                  )),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted,
            ),
          ],
        ),
      ),
    );
  }
}
