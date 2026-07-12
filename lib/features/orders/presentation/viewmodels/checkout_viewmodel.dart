import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/entities/dining_session.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/dining_session_viewmodel.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/loyalty/domain/entities/wallet_entity.dart';

// Provider for tracking which order is being modified (legacy non-session flow)
// ignore: unused_element
final modifyingOrderIdProvider = StateProvider<String?>((ref) => null);

// ── State ─────────────────────────────────────────────────────────────────────

abstract class CheckoutState {
  const CheckoutState();
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

/// Emitted when the order was successfully appended to a session.
class CheckoutSuccess extends CheckoutState {
  final OrderEntity order;
  final DiningSession session;
  const CheckoutSuccess(this.order, this.session);
}

class CheckoutError extends CheckoutState {
  final String message;
  const CheckoutError(this.message);
}

// ── Provider ──────────────────────────────────────────────────────────────────

final checkoutViewModelProvider =
    StateNotifierProvider<CheckoutViewModel, CheckoutState>((ref) {
  return CheckoutViewModel(ref);
});

// ── ViewModel ─────────────────────────────────────────────────────────────────

class CheckoutViewModel extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutViewModel(this._ref) : super(const CheckoutInitial());

  /// DINE-IN FLOW: Appends cart items to the persistent session.
  ///
  /// - Finds or creates the active dining session for this table.
  /// - Calls [appendItemsToSession] — NEVER creates a second order.
  /// - The same [DiningSession.orderNumber] persists across all submissions.
  Future<void> placeOrder({
    required String deliveryAddress,
    required String paymentMethod,
    double discountAmount = 0.0,
    String? tableNumber,
    String? customerName,
    String? specialInstructions,
    double coinsRedeemed = 0.0,
    double coinDiscount = 0.0,
  }) async {
    state = const CheckoutLoading();

    final authState = _ref.read(authViewModelProvider);
    if (authState is! Authenticated) {
      state = const CheckoutError('User must be logged in to order.');
      return;
    }

    final cartItems = _ref.read(cartViewModelProvider);
    if (cartItems.isEmpty) {
      state = const CheckoutError('Cannot place an empty order.');
      return;
    }

    final cartNotifier = _ref.read(cartViewModelProvider.notifier);
    final orderRepository = _ref.read(orderRepositoryProvider);

    // ── DINE-IN: session-based append ──────────────────────────────
    if (tableNumber != null && tableNumber.isNotEmpty) {
      // Step 1: Get or create the active session (idempotent)
      final sessionResult = await orderRepository.getOrCreateActiveSession(
        tableNumber,
        'rest_456', // Restaurant ID
        authState.user.uid,
        customerName ?? authState.user.name,
      );

      DiningSession? session;
      sessionResult.fold(
        (failure) {
          state = CheckoutError(failure.message);
        },
        (s) => session = s,
      );

      if (session == null) return; // Error already set above

      // Step 2: Append items to the session's single master order
      final appendResult = await orderRepository.appendItemsToSession(
        session!.sessionId,
        newItems: cartItems,
        modifiedBy: authState.user.uid,
        specialInstructions: specialInstructions,
        discount: discountAmount,
        coinDiscount: coinDiscount,
        coinsRedeemed: coinsRedeemed,
      );

      appendResult.fold(
        (failure) => state = CheckoutError(failure.message),
        (order) {
          // Deduct coins
          if (coinsRedeemed > 0) {
            final loyaltyRepo = _ref.read(loyaltyRepositoryProvider);
            loyaltyRepo.addTransaction(
              authState.user.uid,
              WalletTransaction(
                id: 'tx_redeem_${DateTime.now().millisecondsSinceEpoch}',
                amount: coinsRedeemed,
                type: 'redeem',
                description:
                    'Redeemed \$${coinDiscount.toStringAsFixed(2)} discount on Order ${session!.orderNumber}',
                createdAt: DateTime.now(),
                restaurantName: 'Gourmet Bistro',
                orderId: order.id,
              ),
            );
          }

          // Update the customer's active session reference
          _ref
              .read(customerActiveSessionProvider.notifier)
              .setSession(session!);

          // Clear cart
          cartNotifier.clearCart();

          // Refresh order history
          _ref
              .read(orderHistoryViewModelProvider.notifier)
              .fetchOrders();

          state = CheckoutSuccess(order, session!);
        },
      );

      return;
    }

    // ── TAKEAWAY / DELIVERY: legacy single-order flow ────────────────
    // (Non-dine-in orders are not subject to the session architecture)
    final legacyResult = await orderRepository.placeOrder(
      OrderEntity(
        id: 'ord_${DateTime.now().millisecondsSinceEpoch}',
        customerId: authState.user.uid,
        restaurantId: 'rest_456',
        items: cartItems
            .map((i) => i.copyWith(status: 'Waiting'))
            .toList(),
        subtotal: cartNotifier.subtotal,
        tax: cartNotifier.tax,
        deliveryFee: cartNotifier.deliveryFee,
        discount: discountAmount + coinDiscount,
        total: (cartNotifier.total - discountAmount - coinDiscount)
            .clamp(0.0, double.infinity),
        status: 'Received',
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        customerName: customerName ?? authState.user.name,
        specialInstructions: specialInstructions,
        coinsRedeemed: coinsRedeemed,
        coinDiscount: coinDiscount,
      ),
    );

    legacyResult.fold(
      (failure) => state = CheckoutError(failure.message),
      (_) {
        cartNotifier.clearCart();
        _ref.read(orderHistoryViewModelProvider.notifier).fetchOrders();
        // For non-session orders, emit a minimal success without session
        state = CheckoutError(
            'Order placed (takeaway/delivery). No live session tracking.');
      },
    );
  }

  void reset() {
    state = const CheckoutInitial();
  }
}
