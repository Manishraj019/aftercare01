import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';

import 'package:restaurantos/features/menu/presentation/screens/customer_landing_screen.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  String _selectedCategory = 'All';
  bool _onlyVeg = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  final List<String> _categories = ['All', 'Starters', 'Mains', 'Desserts', 'Beverages'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final cartItems = ref.watch(cartViewModelProvider);
    final cartNotifier = ref.read(cartViewModelProvider.notifier);
    final selectedTable = ref.watch(selectedTableProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              selectedTable != null ? 'Gourmet Bistro ($selectedTable)' : 'Gourmet Bistro',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const Text('Freshly prepared gourmet dishes', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          // Shopping Cart Action Icon with Badge count
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                key: const Key('cartButton'),
                icon: const Icon(Icons.shopping_bag_outlined, size: 28),
                onPressed: () => context.push('/customer/cart'),
              ),
              if (cartNotifier.itemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cartNotifier.itemCount}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search menu dishes...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      fillColor: Theme.of(context).cardTheme.color?.withValues(alpha: 0.5),
                    ),
                    onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                // Veg toggle chip
                FilterChip(
                  label: const Text('Veg Only'),
                  selected: _onlyVeg,
                  onSelected: (val) => setState(() => _onlyVeg = val),
                  selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                  checkmarkColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

          // Horizontal Category Choice Chips
          SizedBox(
            height: 52,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: _selectedCategory == category,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedCategory = category);
                    },
                  ),
                );
              },
            ),
          ),

          // Menu Grid/List View
          Expanded(
            child: menuState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (items) {
                // Apply search and category filtering logic
                final filteredItems = items.where((item) {
                  final matchesCategory = _selectedCategory == 'All' || item.category == _selectedCategory;
                  final matchesVeg = !_onlyVeg || item.isVegetarian;
                  final matchesSearch = item.name.toLowerCase().contains(_searchQuery) ||
                      item.description.toLowerCase().contains(_searchQuery);
                  return matchesCategory && matchesVeg && matchesSearch;
                }).toList();

                if (filteredItems.isEmpty) {
                  return const Center(child: Text('No menu items match your search.'));
                }

                final screenWidth = MediaQuery.of(context).size.width;
                final crossAxisCount = screenWidth >= 600 ? 3 : 2;

                return GridView.builder(
                  padding: const EdgeInsets.all(12.0),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];

                    // Check if item is in cart to display count stepper or "+ Add"
                    final cartIdx = cartItems.indexWhere((element) => element.itemId == item.id);
                    final quantityInCart = cartIdx >= 0 ? cartItems[cartIdx].quantity : 0;
                    final isTrending = index < 3; // Mark first 3 items as trending
                    final rating = (4.2 + (item.id.hashCode % 8) / 10).toStringAsFixed(1);

                    return InkWell(
                      onTap: () => _showDishDetailBottomSheet(context, item, cartNotifier, cartItems),
                      borderRadius: BorderRadius.circular(16),
                      child: Card(
                        margin: EdgeInsets.zero,
                        clipBehavior: Clip.antiAlias,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Stack(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Dish Image
                                Expanded(
                                  child: Image.network(
                                    item.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, _, _) => Container(
                                      color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                                      child: Icon(Icons.fastfood, color: Theme.of(context).colorScheme.primary, size: 36),
                                    ),
                                  ),
                                ),
                                // Content details
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.fiber_manual_record,
                                            color: item.isVegetarian ? Colors.green : Colors.red,
                                            size: 12,
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              item.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber.shade600, size: 12),
                                          const SizedBox(width: 2),
                                          Text(
                                            rating,
                                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '\$${item.price.toStringAsFixed(2)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                          ),
                                          // Add to cart stepper or button
                                          if (quantityInCart > 0)
                                            Row(
                                              children: [
                                                IconButton(
                                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 18),
                                                  onPressed: () => cartNotifier.updateQuantity(item.id, -1),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6.0),
                                                  child: Text(
                                                    '$quantityInCart',
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                  ),
                                                ),
                                                IconButton(
                                                  icon: const Icon(Icons.add_circle_outline, color: Colors.green, size: 18),
                                                  onPressed: () => cartNotifier.updateQuantity(item.id, 1),
                                                  padding: EdgeInsets.zero,
                                                  constraints: const BoxConstraints(),
                                                ),
                                              ],
                                            )
                                          else
                                            ElevatedButton(
                                              key: Key('addBtn_${item.id}'),
                                              onPressed: () => cartNotifier.addItem(item),
                                              style: ElevatedButton.styleFrom(
                                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                minimumSize: Size.zero,
                                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                              ),
                                              child: const Text('Add', style: TextStyle(fontSize: 11)),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (isTrending)
                              Positioned(
                                top: 8,
                                left: 8,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.redAccent.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.whatshot, color: Colors.white, size: 10),
                                      SizedBox(width: 2),
                                      Text(
                                        'TRENDING',
                                        style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      // Sticky floating bottom cart summary bar
      bottomNavigationBar: cartNotifier.itemCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${cartNotifier.itemCount} Items in bag',
                          style: const TextStyle(color: Colors.white, fontSize: 12),
                        ),
                        Text(
                          'Total \$${cartNotifier.subtotal.toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      key: const Key('viewCartButton'),
                      icon: const Icon(Icons.shopping_bag),
                      label: const Text('View Cart'),
                      onPressed: () => context.push('/customer/cart'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  void _showDishDetailBottomSheet(BuildContext context, dynamic item, CartViewModel cartNotifier, List<dynamic> cartItems) {
    // Check quantity in cart
    final cartIdx = cartItems.indexWhere((element) => element.itemId == item.id);
    int currentQty = cartIdx >= 0 ? cartItems[cartIdx].quantity : 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final hasInCart = currentQty > 0;
            return DraggableScrollableSheet(
              initialChildSize: 0.65,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollController) {
                return SingleChildScrollView(
                  controller: scrollController,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Large Dish Image header
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                            child: Image.network(
                              item.imageUrl,
                              height: 240,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => Container(
                                height: 240,
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                                child: Icon(Icons.restaurant, size: 64, color: Theme.of(context).colorScheme.primary),
                              ),
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              backgroundColor: Colors.white,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.black),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                          ),
                          // Vegetarian Indicator
                          Positioned(
                            bottom: 12,
                            left: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.fiber_manual_record, color: item.isVegetarian ? Colors.green : Colors.red, size: 12),
                                  const SizedBox(width: 4),
                                  Text(
                                    item.isVegetarian ? 'Veg' : 'Non-Veg',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.black87),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                                          const SizedBox(width: 4),
                                          Text(
                                            '${(4.2 + (item.id.hashCode % 8) / 10).toStringAsFixed(1)} (120+ ratings)',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                          ),
                                          const SizedBox(width: 12),
                                          const Icon(Icons.timer_outlined, color: Colors.grey, size: 16),
                                          const SizedBox(width: 4),
                                          const Text('15-20 mins', style: TextStyle(color: Colors.grey, fontSize: 12)),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 22,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                            const SizedBox(height: 6),
                            Text(item.description, style: const TextStyle(fontSize: 14, color: Colors.black54, height: 1.4)),
                            const SizedBox(height: 20),
                            const Text('Chef\'s Tags', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              children: [
                                _tagChip('Spicy 🌶️'),
                                _tagChip('Popular 🔥'),
                                _tagChip('Fresh Ingredients 🌿'),
                              ],
                            ),
                            const SizedBox(height: 32),
                            // Add/Stepping CTA Row
                            Row(
                              children: [
                                if (hasInCart) ...[
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                                        borderRadius: BorderRadius.circular(28),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove, color: Colors.red),
                                            onPressed: () {
                                              cartNotifier.updateQuantity(item.id, -1);
                                              setModalState(() {
                                                currentQty--;
                                              });
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            },
                                          ),
                                          Text(
                                            '$currentQty',
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.add, color: Colors.green),
                                            onPressed: () {
                                              cartNotifier.updateQuantity(item.id, 1);
                                              setModalState(() {
                                                currentQty++;
                                              });
                                              if (mounted) {
                                                setState(() {});
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ] else ...[
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () {
                                        cartNotifier.addItem(item);
                                        setModalState(() {
                                          currentQty = 1;
                                        });
                                        if (mounted) {
                                          setState(() {});
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 16),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                                      ),
                                      child: const Text('Add to Order Bag', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _tagChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(text, style: const TextStyle(fontSize: 11, color: Colors.black87)),
    );
  }
}
