import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/orders/data/repositories/api_order_repository.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';

// Riverpod Provider for Order Repository
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return ApiOrderRepository();
});

// Riverpod StateNotifierProvider for Order History State
final orderHistoryViewModelProvider =
    StateNotifierProvider<OrderHistoryViewModel, AsyncValue<List<OrderEntity>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  final authState = ref.watch(authViewModelProvider);
  String? userId;

  if (authState is Authenticated) {
    userId = authState.user.uid;
  }

  return OrderHistoryViewModel(orderRepository: repo, userId: userId);
});

class OrderHistoryViewModel extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  final OrderRepository _orderRepository;
  final String? _userId;

  OrderHistoryViewModel({
    required this._orderRepository,
    this._userId,
  })  : super(const AsyncLoading()) {
    fetchOrders();
    ApiOrderRepository.addListener(fetchOrders);
  }

  @override
  void dispose() {
    ApiOrderRepository.removeListener(fetchOrders);
    super.dispose();
  }

  Future<void> fetchOrders() async {
    if (_userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncLoading();
    final result = await _orderRepository.getCustomerOrders(_userId!);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (orders) => state = AsyncValue.data(orders),
    );
  }

  Future<void> addOrder(OrderEntity order) async {
    await _orderRepository.placeOrder(order);
    await fetchOrders();
  }
}
