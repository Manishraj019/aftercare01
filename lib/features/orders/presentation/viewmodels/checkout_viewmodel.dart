import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';

abstract class CheckoutState {
  const CheckoutState();
}

class CheckoutInitial extends CheckoutState {
  const CheckoutInitial();
}

class CheckoutLoading extends CheckoutState {
  const CheckoutLoading();
}

class CheckoutSuccess extends CheckoutState {
  final OrderEntity order;
  const CheckoutSuccess(this.order);
}

class CheckoutError extends CheckoutState {
  final String message;
  const CheckoutError(this.message);
}

final checkoutViewModelProvider =
    StateNotifierProvider<CheckoutViewModel, CheckoutState>((ref) {
  return CheckoutViewModel(ref);
});

class CheckoutViewModel extends StateNotifier<CheckoutState> {
  final Ref _ref;

  CheckoutViewModel(this._ref) : super(const CheckoutInitial());

  Future<void> placeOrder({
    required String deliveryAddress,
    required String paymentMethod,
    double discountAmount = 0.0,
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

    final orderId = 'ord_${const Uuid().v4().substring(0, 8)}';
    
    final order = OrderEntity(
      id: orderId,
      customerId: authState.user.uid,
      restaurantId: 'rest_456', // Default simulated restaurant ID
      items: cartItems,
      subtotal: cartNotifier.subtotal,
      tax: cartNotifier.tax,
      deliveryFee: cartNotifier.deliveryFee,
      discount: discountAmount,
      total: (cartNotifier.total - discountAmount).clamp(0.0, double.infinity),
      status: 'placed',
      deliveryAddress: deliveryAddress,
      paymentMethod: paymentMethod,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final result = await orderRepository.placeOrder(order);

    result.fold(
      (failure) => state = CheckoutError(failure.message),
      (_) {
        // Clear cart locally
        cartNotifier.clearCart();
        // Refresh Order History
        _ref.read(orderHistoryViewModelProvider.notifier).fetchOrders();
        state = CheckoutSuccess(order);
      },
    );
  }

  void reset() {
    state = const CheckoutInitial();
  }
}
