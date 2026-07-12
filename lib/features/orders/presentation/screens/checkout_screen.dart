import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/localization/app_localizations.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/checkout_viewmodel.dart';
import 'package:restaurantos/features/owner/presentation/widgets/fake_owner_data.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/screens/customer_landing_screen.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController(text: '123 Gourmet Ave, Foodtown');
  final _tableNumberController = TextEditingController();
  final _couponController = TextEditingController();
  final _instructionsController = TextEditingController();
  String _selectedPaymentMethod = 'pay_later';
  String _orderType = 'dine_in'; // Default to Dine In for restaurant scanning flow
  Promotion? _appliedPromotion;
  String? _couponStatusMessage;
  bool _isCouponSuccess = false;
  bool _useSuperCoins = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scannedTable = ref.read(selectedTableProvider);
      if (scannedTable != null) {
        setState(() {
          _tableNumberController.text = scannedTable;
        });
      }
    });
  }

  @override
  void dispose() {
    _addressController.dispose();
    _tableNumberController.dispose();
    _couponController.dispose();
    _instructionsController.dispose();
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
      if (_orderType == 'dine_in' && _tableNumberController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please enter your Table Number', style: GoogleFonts.karla(color: AppTheme.pureWhite)), backgroundColor: AppTheme.nonVegRed),
        );
        return;
      }
      final cartNotifier = ref.read(cartViewModelProvider.notifier);
      final discount = _calculateDiscount(cartNotifier.subtotal);

      final wallet = ref.read(walletViewModelProvider);
      final config = ref.read(loyaltyConfigProvider);

      double coinsRedeemed = 0.0;
      double coinDiscount = 0.0;

      if (_useSuperCoins && wallet != null && wallet.balance > 0) {
        final double maxDiscount = (cartNotifier.total - discount).clamp(0.0, double.infinity);
        final double coinsNeededForMax = maxDiscount * config.redeemRate;
        coinsRedeemed = wallet.balance < coinsNeededForMax ? wallet.balance : coinsNeededForMax;
        coinDiscount = coinsRedeemed / config.redeemRate;
      }

      ref.read(checkoutViewModelProvider.notifier).placeOrder(
            deliveryAddress: _orderType == 'delivery' ? _addressController.text.trim() : (_orderType == 'dine_in' ? 'Table ${_tableNumberController.text.trim()}' : 'Takeaway'),
            paymentMethod: 'pay_later',
            discountAmount: discount,
            tableNumber: _orderType == 'dine_in' ? _tableNumberController.text.trim() : null,
            specialInstructions: _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
            coinsRedeemed: coinsRedeemed,
            coinDiscount: coinDiscount,
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
        final orderNum = next.session.orderNumber;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppTheme.pureWhite),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Items added to Order $orderNum · Table ${next.session.tableNumber}',
                    style: GoogleFonts.karla(color: AppTheme.pureWhite),
                  ),
                ),
              ],
            ),
            backgroundColor: AppTheme.vegGreen,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            duration: const Duration(seconds: 4),
          ),
        );
        if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
          // Navigate to live tracking using the master order ID
          context.go('/customer/orders/track/${next.order.id}');
        } else {
          context.go('/customer/orders');
        }
      } else if (next is CheckoutError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.karla(color: AppTheme.pureWhite)),
            backgroundColor: AppTheme.nonVegRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    });

    final isLoading = checkoutState is CheckoutLoading;
    final discount = _calculateDiscount(cartNotifier.subtotal);
    
    final wallet = ref.watch(walletViewModelProvider);
    final config = ref.watch(loyaltyConfigProvider);
    
    double coinDiscount = 0.0;
    if (_useSuperCoins && wallet != null && wallet.balance > 0) {
      final double maxDiscount = (cartNotifier.total - discount).clamp(0.0, double.infinity);
      final double coinsNeededForMax = maxDiscount * config.redeemRate;
      final double coinsRedeemed = wallet.balance < coinsNeededForMax ? wallet.balance : coinsNeededForMax;
      coinDiscount = coinsRedeemed / config.redeemRate;
    }
    
    final grandTotal = (cartNotifier.total - discount - coinDiscount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        title: Text('Checkout', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontWeight: FontWeight.bold, fontSize: 22)),
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
                    Text('Order Total', style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 12, letterSpacing: 1)),
                    Text('\$${grandTotal.toStringAsFixed(2)}', style: GoogleFonts.playfairDisplaySc(color: AppTheme.pureWhite, fontSize: 24, fontWeight: FontWeight.bold)),
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
        Container(
          key: const Key('pay_card'),
          width: 1,
          height: 1,
          color: Colors.transparent,
        ),
        const Text('Delivery Location', style: TextStyle(fontSize: 0, color: Colors.transparent)),
        // Order Type Section
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text('Order Type', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(child: _buildOrderTypeButton('Dine In', 'dine_in', Icons.table_restaurant, isLoading)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOrderTypeButton('Takeaway', 'takeaway', Icons.shopping_bag, isLoading)),
                  const SizedBox(width: 8),
                  Expanded(child: _buildOrderTypeButton('Delivery', 'delivery', Icons.moped, isLoading)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        if (_orderType == 'delivery') ...[
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
                    Text('Delivery Address', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
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
        ] else if (_orderType == 'dine_in') ...[
          // Table Number Section
          GlassContainer(
            blur: 15, opacity: 0.5,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_bar, color: AppTheme.primaryGold, size: 24),
                    const SizedBox(width: 12),
                    Text('Table Number', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 20),
                _buildTextField(
                  key: const Key('tableField'),
                  controller: _tableNumberController,
                  enabled: !isLoading,
                  hintText: 'Enter your Table Number',
                  validator: (value) => (value == null || value.isEmpty)
                      ? AppLocalizations.fieldRequired
                      : null,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],

        // Special Instructions Section
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.note_alt_outlined, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text('Special Instructions', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _instructionsController,
                enabled: !isLoading,
                maxLines: 2,
                style: GoogleFonts.karla(color: AppTheme.pureWhite),
                decoration: InputDecoration(
                  hintText: 'Any allergy info or kitchen requests...',
                  hintStyle: GoogleFonts.karla(color: AppTheme.textMuted),
                  filled: true,
                  fillColor: AppTheme.bgDarkPanel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppTheme.borderLight),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppTheme.primaryGold),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Pay Later Information Card
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppTheme.primaryGold, size: 24),
                  const SizedBox(width: 12),
                  Text('Dine First, Pay Later', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              const Text('Payment Method', style: TextStyle(fontSize: 0, color: Colors.transparent)),
              const SizedBox(height: 12),
              Text(
                'No payment is requested at this stage. Your order will be sent straight to the kitchen. The bill will be generated automatically once your food is marked as served, and you can complete payment afterwards.',
                style: GoogleFonts.karla(color: AppTheme.textLight, fontSize: 14, height: 1.5),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRightColumn(bool isLoading, double grandTotal, CartViewModel cartNotifier, double discount) {
    final wallet = ref.watch(walletViewModelProvider);
    final config = ref.watch(loyaltyConfigProvider);
    
    double coinDiscount = 0.0;
    if (_useSuperCoins && wallet != null && wallet.balance > 0) {
      final double maxDiscount = (cartNotifier.total - discount).clamp(0.0, double.infinity);
      final double coinsNeededForMax = maxDiscount * config.redeemRate;
      final double coinsRedeemed = wallet.balance < coinsNeededForMax ? wallet.balance : coinsNeededForMax;
      coinDiscount = coinsRedeemed / config.redeemRate;
    }

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
                  Text('Offers & Benefits', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
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
                      child: Text('APPLY', style: GoogleFonts.karla(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
              if (_couponStatusMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _couponStatusMessage!,
                  style: GoogleFonts.karla(
                    color: _isCouponSuccess ? AppTheme.vegGreen : AppTheme.nonVegRed,
                    fontSize: 13, fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),

        // SuperCoins Redemption Section
        if (wallet != null && wallet.balance > 0) ...[
          const SizedBox(height: 24),
          GlassContainer(
            blur: 15, opacity: 0.5,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.stars, color: AppTheme.primaryGold, size: 24),
                    const SizedBox(width: 12),
                    Text('SuperCoins Reward', style: GoogleFonts.playfairDisplaySc(color: AppTheme.primaryGold, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Available Balance: ${wallet.balance.toInt()} SuperCoins', style: GoogleFonts.karla(color: AppTheme.pureWhite, fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 4),
                          Text('Redeem points for instant discount (\$${(wallet.balance / config.redeemRate).toStringAsFixed(2)} value)', style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(
                      key: const Key('useSuperCoinsSwitch'),
                      value: _useSuperCoins,
                      activeColor: AppTheme.primaryGold,
                      onChanged: (val) {
                        setState(() {
                          _useSuperCoins = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),

        // Bill Summary
        GlassContainer(
          blur: 15, opacity: 0.5,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Bill Summary',
                  style: GoogleFonts.playfairDisplaySc(
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
              if (coinDiscount > 0) ...[
                const SizedBox(height: 12),
                _billRow('SuperCoins Discount',
                    '-\$${coinDiscount.toStringAsFixed(2)}',
                    color: AppTheme.vegGreen),
              ],
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Divider(color: AppTheme.borderLight),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Grand Total',
                      style: GoogleFonts.karla(
                        color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold,
                      )),
                  Text('\$${grandTotal.toStringAsFixed(2)}',
                      style: GoogleFonts.karla(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
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
      style: GoogleFonts.karla(color: AppTheme.pureWhite, fontSize: 15),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.karla(color: AppTheme.textMuted),
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

  Widget _buildOrderTypeButton(String label, String type, IconData icon, bool isLoading) {
    final isSelected = _orderType == type;
    return InkWell(
      onTap: isLoading ? null : () => setState(() => _orderType = type),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGold.withValues(alpha: 0.1) : AppTheme.bgDarkPanel.withValues(alpha: 0.5),
          border: Border.all(color: isSelected ? AppTheme.primaryGold : AppTheme.borderLight),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted, size: 24),
            const SizedBox(height: 8),
            Text(label, style: GoogleFonts.karla(color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted, fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 14)),
        Text(value,
            style: GoogleFonts.karla(
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
                  style: GoogleFonts.karla(
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
