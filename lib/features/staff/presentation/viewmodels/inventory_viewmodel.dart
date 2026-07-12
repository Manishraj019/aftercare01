import 'package:flutter_riverpod/flutter_riverpod.dart';

class InventoryItem {
  final String id;
  final String name;
  final double currentQuantity;
  final double minQuantity;
  final String unit;

  InventoryItem({
    required this.id,
    required this.name,
    required this.currentQuantity,
    required this.minQuantity,
    required this.unit,
  });

  bool get isLowStock => currentQuantity <= minQuantity;

  InventoryItem copyWith({
    String? id,
    String? name,
    double? currentQuantity,
    double? minQuantity,
    String? unit,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      minQuantity: minQuantity ?? this.minQuantity,
      unit: unit ?? this.unit,
    );
  }
}

class InventoryViewModel extends StateNotifier<List<InventoryItem>> {
  InventoryViewModel() : super([]) {
    _loadInitialMockInventory();
  }

  void _loadInitialMockInventory() {
    state = [
      InventoryItem(id: 'i1', name: 'Pizza Dough', currentQuantity: 50, minQuantity: 20, unit: 'pcs'),
      InventoryItem(id: 'i2', name: 'Cheese', currentQuantity: 5.0, minQuantity: 10.0, unit: 'kg'),
      InventoryItem(id: 'i3', name: 'Tomato Sauce', currentQuantity: 15.0, minQuantity: 5.0, unit: 'liters'),
      InventoryItem(id: 'i4', name: 'Truffle Oil', currentQuantity: 0.5, minQuantity: 1.0, unit: 'liters'),
      InventoryItem(id: 'i5', name: 'Pasta', currentQuantity: 25.0, minQuantity: 10.0, unit: 'kg'),
    ];
  }

  void updateStock(String id, double delta) {
    state = state.map((item) {
      if (item.id == id) {
        return item.copyWith(currentQuantity: (item.currentQuantity + delta).clamp(0, double.infinity));
      }
      return item;
    }).toList();
  }

  bool checkAvailability(Map<String, double> requiredIngredients) {
    for (final entry in requiredIngredients.entries) {
      final item = state.firstWhere((i) => i.name.toLowerCase() == entry.key.toLowerCase(), orElse: () => InventoryItem(id: '', name: '', currentQuantity: 0, minQuantity: 0, unit: ''));
      if (item.currentQuantity < entry.value) {
        return false;
      }
    }
    return true;
  }

  void deductIngredients(Map<String, double> requiredIngredients) {
    for (final entry in requiredIngredients.entries) {
      final itemIndex = state.indexWhere((i) => i.name.toLowerCase() == entry.key.toLowerCase());
      if (itemIndex != -1) {
        final item = state[itemIndex];
        state[itemIndex] = item.copyWith(currentQuantity: (item.currentQuantity - entry.value).clamp(0, double.infinity));
      }
    }
    // Trigger state update
    state = [...state];
  }
}

final inventoryViewModelProvider = StateNotifierProvider<InventoryViewModel, List<InventoryItem>>((ref) {
  return InventoryViewModel();
});
