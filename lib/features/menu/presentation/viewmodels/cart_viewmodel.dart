import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/menu/data/repositories/api_cart_repository.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/cart_repository.dart';

// Riverpod Provider for Cart Repository
final cartRepositoryProvider = Provider<CartRepository>((ref) {
  return ApiCartRepository();
});

// Riverpod StateNotifierProvider for Cart State
final cartViewModelProvider =
    StateNotifierProvider<CartViewModel, List<CartItemEntity>>((ref) {
  final repo = ref.watch(cartRepositoryProvider);
  final authState = ref.watch(authViewModelProvider);
  String? userId;

  if (authState is Authenticated) {
    userId = authState.user.uid;
  }

  return CartViewModel(cartRepository: repo, userId: userId);
});

class CartViewModel extends StateNotifier<List<CartItemEntity>> {
  final CartRepository _cartRepository;
  final String? _userId;

  CartViewModel({
    required this._cartRepository,
    this._userId,
  })  : super([]) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    if (_userId == null) return;
    final result = await _cartRepository.fetchCart(_userId);
    result.fold(
      (_) => null,
      (items) => state = items,
    );
  }

  void addItem(MenuItemEntity item) {
    addItemWithCustomizations(item);
  }

  void addItemWithCustomizations(
    MenuItemEntity item, {
    String? notes,
    String? spiceLevel,
    List<String>? addOns,
    double addedPrice = 0.0,
    int quantity = 1,
  }) {
    // Unique key to distinguish different customization profiles in the cart
    final String customItemId = '${item.id}_${spiceLevel ?? ""}_${addOns?.join(",") ?? ""}_${notes ?? ""}';
    final existingIndex = state.indexWhere((element) => element.itemId == customItemId);

    if (existingIndex >= 0) {
      final existingItem = state[existingIndex];
      state = [
        for (int i = 0; i < state.length; i++)
          if (i == existingIndex)
            existingItem.copyWith(quantity: existingItem.quantity + quantity)
          else
            state[i]
      ];
    } else {
      state = [
        ...state,
        CartItemEntity(
          itemId: customItemId,
          name: item.name,
          price: item.price + addedPrice,
          quantity: quantity,
          imageUrl: item.imageUrl,
          notes: notes,
          spiceLevel: spiceLevel,
          addOns: addOns,
        )
      ];
    }
    _sync();
  }

  void updateQuantity(String itemId, int change) {
    state = state
        .map((item) {
          if (item.itemId == itemId) {
            final newQty = item.quantity + change;
            return newQty > 0 ? item.copyWith(quantity: newQty) : null;
          }
          return item;
        })
        .whereType<CartItemEntity>()
        .toList();
    _sync();
  }

  void removeItem(String itemId) {
    state = state.where((item) => item.itemId != itemId).toList();
    _sync();
  }

  void clearCart() {
    state = [];
    _sync();
  }

  void setCartItems(List<CartItemEntity> items) {
    state = items;
    _sync();
  }

  void _sync() {
    if (_userId == null) return;
    _cartRepository.syncCart(_userId, state);
  }

  // Summary Computations
  double get subtotal => state.fold(0.0, (sum, item) => sum + item.total);
  double get tax => subtotal * 0.08; // 8% GST/Sales tax
  double get deliveryFee => subtotal > 0 ? 5.00 : 0.00; // Flat $5 delivery
  double get total => subtotal + tax + deliveryFee;
  int get itemCount => state.fold(0, (sum, item) => sum + item.quantity);
}
