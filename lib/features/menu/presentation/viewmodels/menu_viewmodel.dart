import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/menu/data/repositories/menu_repository_impl.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/domain/repositories/menu_repository.dart';

// Riverpod Provider for Menu Repository
final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepositoryImpl();
});

// Riverpod StateNotifierProvider for Menu State
final menuViewModelProvider =
    StateNotifierProvider<MenuViewModel, AsyncValue<List<MenuItemEntity>>>((ref) {
  return MenuViewModel(menuRepository: ref.watch(menuRepositoryProvider));
});

class MenuViewModel extends StateNotifier<AsyncValue<List<MenuItemEntity>>> {
  final MenuRepository _menuRepository;

  MenuViewModel({required this._menuRepository})
      : super(const AsyncLoading()) {
    // Fetch menu for default restaurant rest_456 on initialization
    fetchMenu('rest_456');
  }

  Future<void> fetchMenu(String restaurantId) async {
    state = const AsyncLoading();
    final result = await _menuRepository.getMenuItems(restaurantId);
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (items) => state = AsyncValue.data(items),
    );
  }

  void addItemToMockList(MenuItemEntity item) {
    state.whenData((items) {
      state = AsyncValue.data([...items, item]);
    });
  }

  void removeItemFromMockList(String itemId) {
    state.whenData((items) {
      state = AsyncValue.data(items.where((i) => i.id != itemId).toList());
    });
  }

  void updateItemInMockList(MenuItemEntity updatedItem) {
    state.whenData((items) {
      state = AsyncValue.data([
        for (final item in items)
          if (item.id == updatedItem.id) updatedItem else item
      ]);
    });
  }
}
