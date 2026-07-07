import 'package:flutter/material.dart';
import 'package:restaurantos/core/theme/block_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/menu_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';
import 'package:restaurantos/features/orders/domain/repositories/order_repository.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/owner/presentation/widgets/fake_owner_data.dart';
import 'package:restaurantos/features/menu/domain/entities/cart_item_entity.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

// StateNotifier to manage Owner orders dashboard feed
final ownerOrdersProvider =
    StateNotifierProvider<OwnerOrdersNotifier, AsyncValue<List<OrderEntity>>>((ref) {
  final repo = ref.watch(orderRepositoryProvider);
  return OwnerOrdersNotifier(repo, ref);
});

class OwnerOrdersNotifier extends StateNotifier<AsyncValue<List<OrderEntity>>> {
  final OrderRepository _repo;
  final Ref _ref;

  OwnerOrdersNotifier(this._repo, this._ref) : super(const AsyncLoading()) {
    fetchOrders();
  }

  Future<void> fetchOrders() async {
    state = const AsyncLoading();
    final result = await _repo.getCustomerOrders('owner_feed');
    result.fold(
      (failure) => state = AsyncValue.error(failure.message, StackTrace.current),
      (orders) => state = AsyncValue.data(orders),
    );
  }

  Future<void> updateStatus(String orderId, String status) async {
    await _repo.updateOrderStatus(orderId, status);
    await fetchOrders();
    _ref.read(orderHistoryViewModelProvider.notifier).fetchOrders();
  }

  Future<void> addMockOrder(OrderEntity order) async {
    await _repo.placeOrder(order);
    await fetchOrders();
  }
}

// Local State for Interactive Seating Tables
class TableState {
  final String id;
  final int capacity;
  String status; // 'available', 'occupied', 'reserved'
  List<CartItemEntity> activeOrderItems;
  String? mergedWithTableId;

  TableState({
    required this.id,
    required this.capacity,
    required this.status,
    this.activeOrderItems = const [],
    this.mergedWithTableId,
  });
}

final tableStateProvider = StateProvider<List<TableState>>((ref) {
  return [
    TableState(id: 'T-01', capacity: 2, status: 'occupied', activeOrderItems: [
      const CartItemEntity(itemId: 'menu_002', name: 'Wood-Fired Pepperoni Pizza', price: 16.00, quantity: 2, imageUrl: ''),
      const CartItemEntity(itemId: 'menu_005', name: 'Fresh Mint Lime Mojito', price: 6.00, quantity: 2, imageUrl: ''),
    ]),
    TableState(id: 'T-02', capacity: 4, status: 'available'),
    TableState(id: 'T-03', capacity: 4, status: 'reserved'),
    TableState(id: 'T-04', capacity: 6, status: 'occupied', activeOrderItems: [
      const CartItemEntity(itemId: 'menu_001', name: 'Truffle Mushroom Fettuccine', price: 18.50, quantity: 3, imageUrl: ''),
      const CartItemEntity(itemId: 'menu_004', name: 'Molten Chocolate Lava Cake', price: 8.50, quantity: 2, imageUrl: ''),
    ]),
    TableState(id: 'T-05', capacity: 2, status: 'available'),
    TableState(id: 'T-06', capacity: 8, status: 'available'),
    TableState(id: 'T-07', capacity: 4, status: 'occupied', activeOrderItems: [
      const CartItemEntity(itemId: 'menu_002', name: 'Wood-Fired Pepperoni Pizza', price: 16.00, quantity: 1, imageUrl: ''),
    ]),
    TableState(id: 'T-08', capacity: 4, status: 'available'),
  ];
});

class OwnerDashboardScreen extends ConsumerStatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  ConsumerState<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends ConsumerState<OwnerDashboardScreen> {
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeDashboardForCurrentShop();
    });
  }

  void _initializeDashboardForCurrentShop() {
    final authState = ref.read(authViewModelProvider);
    if (authState is Authenticated) {
      final email = authState.user.email;
      VirtualShop? matchingShop;
      try {
        matchingShop = FakeOwnerData.virtualShops.firstWhere(
          (shop) => shop.email.toLowerCase() == email.toLowerCase(),
        );
      } catch (_) {}

      if (matchingShop != null) {
        final tableCapacity = matchingShop.tableCapacity;
        final List<TableState> initialTables = List.generate(tableCapacity, (index) {
          final id = 'T-${(index + 1).toString().padLeft(2, '0')}';
          final isOccupied = index == 0 || index == 3 || index == 6;
          final isReserved = index == 2;
          return TableState(
            id: id,
            capacity: (index % 2 == 0) ? 2 : 4,
            status: isOccupied ? 'occupied' : (isReserved ? 'reserved' : 'available'),
            activeOrderItems: (index == 0)
                ? [
                    const CartItemEntity(itemId: 'menu_002', name: 'Wood-Fired Pepperoni Pizza', price: 16.00, quantity: 2, imageUrl: ''),
                    const CartItemEntity(itemId: 'menu_005', name: 'Fresh Mint Lime Mojito', price: 6.00, quantity: 2, imageUrl: ''),
                  ]
                : (index == 3)
                    ? [
                        const CartItemEntity(itemId: 'menu_001', name: 'Truffle Mushroom Fettuccine', price: 18.50, quantity: 3, imageUrl: ''),
                        const CartItemEntity(itemId: 'menu_004', name: 'Molten Chocolate Lava Cake', price: 8.50, quantity: 2, imageUrl: ''),
                      ]
                    : (index == 6)
                        ? [
                            const CartItemEntity(itemId: 'menu_002', name: 'Wood-Fired Pepperoni Pizza', price: 16.00, quantity: 1, imageUrl: ''),
                          ]
                        : const [],
          );
        });
        ref.read(tableStateProvider.notifier).state = initialTables;
      }
    }
  }

  final List<Map<String, dynamic>> _sidebarItems = [
    {'icon': Icons.dashboard_outlined, 'label': 'Dashboard Overview'},
    {'icon': Icons.psychology_outlined, 'label': 'Analytics'},
    {'icon': Icons.kitchen_outlined, 'label': 'KDS Active'},
    {'icon': Icons.table_restaurant_outlined, 'label': 'POS & Seating'},
    {'icon': Icons.restaurant_menu_outlined, 'label': 'Menu Editor'},
    {'icon': Icons.inventory_2_outlined, 'label': 'Staff & Inventory'},
    {'icon': Icons.campaign_outlined, 'label': 'Promos & Social'},
    {'icon': Icons.reviews_outlined, 'label': 'Customers & Reviews'},
    {'icon': Icons.settings_outlined, 'label': 'Console Settings'},
  ];

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 600;

    Widget body = _getBody(_selectedTabIndex);

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Premium sidebar navigation console
            Container(
              width: 250,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                border: Border(
                  right: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        Icon(
                          Icons.restaurant,
                          color: Theme.of(context).colorScheme.primary,
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BistroOS',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                            Text(
                              'OWNER CONSOLE',
                              style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _sidebarItems.length,
                      itemBuilder: (context, index) {
                        final item = _sidebarItems[index];
                        final isSelected = _selectedTabIndex == index;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedTabIndex = index;
                              });
                            },
                            borderRadius: BorderRadius.zero,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    item['icon'] as IconData,
                                    color: isSelected
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      item['label'] as String,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected
                                            ? Theme.of(context).colorScheme.primary
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: () => context.go('/login'),
                      icon: const Icon(Icons.logout),
                      label: const Text('Log Out'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Colors.redAccent),
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Scaffold(
                appBar: AppBar(
                  elevation: 0,
                  backgroundColor: Theme.of(context).colorScheme.surface,
                  title: const Text(
                    'Owner OS Dashboard',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  actions: [
                    _NotificationBellWidget(),
                    const SizedBox(width: 16),
                  ],
                ),
                body: body,
              ),
            ),
          ],
        ),
      );
    } else {
      // Mobile / Portrait view
      return Scaffold(
        appBar: AppBar(
          title: const Text('Owner OS Dashboard'),
          actions: [
            _NotificationBellWidget(),
            const SizedBox(width: 8),
          ],
        ),
        drawer: Drawer(
          child: Column(
            children: [
              DrawerHeader(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: const Row(
                  children: [
                    Icon(Icons.restaurant, color: Colors.white, size: 36),
                    SizedBox(width: 16),
                    Text(
                      'BistroOS',
                      style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _sidebarItems.length,
                  itemBuilder: (context, index) {
                    final item = _sidebarItems[index];
                    final isSelected = _selectedTabIndex == index;
                    return ListTile(
                      leading: Icon(item['icon'] as IconData, color: isSelected ? Theme.of(context).colorScheme.primary : null),
                      title: Text(
                        item['label'] as String,
                        style: TextStyle(fontWeight: isSelected ? FontWeight.bold : null),
                      ),
                      selected: isSelected,
                      onTap: () {
                        setState(() {
                          _selectedTabIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.redAccent),
                title: const Text('Log Out', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.pop(context);
                  context.go('/login');
                },
              ),
            ],
          ),
        ),
        body: body,
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _selectedTabIndex < 4 ? _selectedTabIndex : 0,
          type: BottomNavigationBarType.fixed,
          onTap: (index) {
            setState(() {
              _selectedTabIndex = index;
            });
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Overview'),
            BottomNavigationBarItem(icon: Icon(Icons.psychology_outlined), label: 'AI Coach'),
            BottomNavigationBarItem(icon: Icon(Icons.kitchen_outlined), label: 'KDS'),
            BottomNavigationBarItem(icon: Icon(Icons.table_restaurant_outlined), label: 'Seating'),
          ],
        ),
      );
    }
  }

  Widget _getBody(int index) {
    switch (index) {
      case 0:
        return const _DashboardTab();
      case 1:
        return const _AiCoachTab();
      case 2:
        return const _KdsTab();
      case 3:
        return const _TablePosTab();
      case 4:
        return const _MenuEditorTab();
      case 5:
        return const _StaffInventoryTab();
      case 6:
        return const _PromoSocialTab();
      case 7:
        return const _CustomerReviewsTab();
      case 8:
        return const _SettingsTab();
      default:
        return const _DashboardTab();
    }
  }
}

// -------------------------------------------------------------
// 0. Dashboard Tab Widget
// -------------------------------------------------------------
class _DashboardTab extends ConsumerWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ownerOrdersProvider);

    return ordersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (orders) {
        final completed = orders.where((o) => o.status == 'delivered').toList();
        final totalSales = completed.fold<double>(0, (sum, o) => sum + o.total);
        final pending = orders.where((o) => o.status != 'delivered' && o.status != 'cancelled').toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome back, Alessandro!',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Text('Gourmet Bistro Main Branch Console', style: TextStyle(color: Colors.grey, fontSize: 12), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 8),
                        const SizedBox(width: 8),
                        Text('System Online', style: TextStyle(color: Colors.green.shade800, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // KPI Row
              LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth < 640 ? 2 : 4;
                  final kpiWidth = (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _kpiCard(context, 'Today\'s Sales', '\$${totalSales.toStringAsFixed(2)}', Icons.payments, Colors.blue, '+14% vs yesterday', kpiWidth),
                      _kpiCard(context, 'Total Orders', '${orders.length}', Icons.shopping_bag, Colors.amber, '${pending.length} cooking', kpiWidth),
                      _kpiCard(context, 'Active Seating', '6 / 12', Icons.table_restaurant, Colors.orange, '50% Occupied', kpiWidth),
                      _kpiCard(context, 'Customer Count', '42 guests', Icons.people, Colors.green, 'High engagement', kpiWidth),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),

              // Chart & Recent activity section
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: BlockContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Peak Sales Velocity (Hourly)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              height: 150,
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    _bar(context, '12 PM', 50.0),
                                    _bar(context, '2 PM', 80.0),
                                    _bar(context, '4 PM', 40.0),
                                    _bar(context, '6 PM', 100.0),
                                    _bar(context, '8 PM', 75.0),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: BlockContainer(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Live POS Bill Generator',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: orders.length > 3 ? 3 : orders.length,
                              itemBuilder: (context, idx) {
                                final order = orders[idx];
                                return _billGeneratorTile(context, order);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // AI coach card
              BlockContainer(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.2),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Icon(Icons.psychology, size: 40, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'AI Coach Recommendation',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Demand for Truffle Mushroom Fettuccine is expected to spike by 25% this evening. Consider prepping 5 kg extra fresh pasta.',
                              style: TextStyle(fontSize: 12, color: Colors.black87),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _kpiCard(BuildContext context, String label, String value, IconData icon, Color color, String footer, double width) {
    return Container(
      width: width < 150 ? 150 : width,
      constraints: const BoxConstraints(minWidth: 160),
      child: BlockContainer(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                  Icon(icon, color: color, size: 20),
                ],
              ),
              const SizedBox(height: 8),
              Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(footer, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bar(BuildContext context, String label, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 24,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            borderRadius: BorderRadius.zero,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 9, color: Colors.grey)),
      ],
    );
  }

  Widget _billGeneratorTile(BuildContext context, OrderEntity order) {
    final subtotal = order.items.fold<double>(0, (sum, item) => sum + item.price * item.quantity);
    final gst = subtotal * 0.18;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order #${order.id.substring(order.id.length - 4).toUpperCase()} (${order.deliveryAddress})',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Subtotal: \$${subtotal.toStringAsFixed(2)} • GST: \$${gst.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 9, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _showInvoiceDialog(context, order),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: const Size(60, 24),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Gen Bill', style: TextStyle(fontSize: 9)),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 1. AI Business Coach & Analytics Tab Widget
// -------------------------------------------------------------
class _AiCoachTab extends StatefulWidget {
  const _AiCoachTab();

  @override
  State<_AiCoachTab> createState() => _AiCoachTabState();
}

class _AiCoachTabState extends State<_AiCoachTab> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _chatController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hello Chef Russo! I have completed today\'s analysis.\nOur business health score is 94/100.\nHow can I help you improve margins or optimize stock today?'
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chatController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _chatController.clear();
    });

    // Simulate AI response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      String reply = '';
      final lowerText = text.toLowerCase();

      if (lowerText.contains('waste') || lowerText.contains('reduce')) {
        reply = 'Based on ingredient tracking, Fresh Basil Leaves have the highest discard rate (22%). I recommend reducing weekly herb purchase orders by 10% or introducing a Basil Pesto sauce special.';
      } else if (lowerText.contains('peak') || lowerText.contains('hour')) {
        reply = 'Our peak customer volume is between 6:00 PM and 8:00 PM, accounting for 45% of daily revenue. I suggest scheduling 1 extra server for this shift.';
      } else if (lowerText.contains('price') || lowerText.contains('pricing') || lowerText.contains('margin') || lowerText.contains('profitable') || lowerText.contains('least')) {
        if (lowerText.contains('least') || lowerText.contains('lowest')) {
          reply = 'The Lasagna is currently your least profitable dish due to high prep time and expensive ricotta imports, operating at a 42% margin. I recommend a 5% price adjustment or running a combo deal with higher-margin drinks.';
        } else {
          reply = 'Your Pepperoni Pizza has a very healthy 68.4% profit margin. The Fresh Mint Lime Mojito has your highest margin at 82%. I suggest bundling them as a "Spicy & Sweet Combo" for \$20 to increase ticket sizes.';
        }
      } else if (lowerText.contains('forecast') || lowerText.contains('weekend')) {
        reply = 'Based on previous weekend patterns and local sunny weather forecasts, we expect Saturday and Sunday revenue to reach \$4,150. Prep additional dough for Pepperoni Pizzas.';
      } else {
        reply = 'That sounds like a great strategy! I will track the performance impact and report back in our daily summary.';
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': reply});
      });
    });
  }

  void _sendSuggestion(String prompt) {
    _chatController.text = prompt;
    _sendMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '📊 Business Analytics'),
              Tab(text: '🤖 AI Business Coach'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Subtab 1: Business Analytics
          _buildAnalyticsView(),
          // Subtab 2: AI Business Coach
          _buildCoachView(),
        ],
      ),
    );
  }

  Widget _buildAnalyticsView() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isLarge = screenWidth >= 900;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildKpiRow(),
          const SizedBox(height: 16),
          if (isLarge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _buildRevenueChart()),
                const SizedBox(width: 16),
                Expanded(flex: 2, child: _buildCategoryRevenue()),
              ],
            )
          else ...[
            _buildRevenueChart(),
            const SizedBox(height: 16),
            _buildCategoryRevenue(),
          ],
          const SizedBox(height: 16),
          if (isLarge)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildTopDishes()),
                const SizedBox(width: 16),
                Expanded(child: _buildTrafficHeatmap()),
              ],
            )
          else ...[
            _buildTopDishes(),
            const SizedBox(height: 16),
            _buildTrafficHeatmap(),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiRow() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth < 600 ? 1 : 3;
        final kpiWidth = (constraints.maxWidth - (crossAxisCount - 1) * 8) / crossAxisCount;

        final items = [
          _kpiItem('Today\'s Revenue', '\$1,248.50', '+12.4% vs last week', Colors.green, kpiWidth),
          _kpiItem('Avg Order Value', '\$29.72', '+3.1% this month', Colors.green, kpiWidth),
          _kpiItem('Net Margin', '28.4%', 'Stable at 28.4%', Colors.blue, kpiWidth),
        ];

        if (crossAxisCount == 1) {
          return Column(
            children: items.map((w) => Padding(padding: const EdgeInsets.only(bottom: 8.0), child: w)).toList(),
          );
        }

        return Row(
          children: items.map((w) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4.0), child: w))).toList(),
        );
      },
    );
  }

  Widget _kpiItem(String label, String value, String footer, Color color, double width) {
    return BlockContainer(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(footer, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart() {
    final data = [
      {'day': 'Mon', 'value': 850.0},
      {'day': 'Tue', 'value': 980.0},
      {'day': 'Wed', 'value': 1100.0},
      {'day': 'Thu', 'value': 1250.0},
      {'day': 'Fri', 'value': 1850.0},
      {'day': 'Sat', 'value': 2200.0},
      {'day': 'Sun', 'value': 1950.0},
    ];
    final maxVal = 2200.0;
    return BlockContainer(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('7-Day Revenue Trend', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 24),
            SizedBox(
              height: 180,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: data.map((item) {
                  final val = item['value'] as double;
                  final day = item['day'] as String;
                  final pct = val / maxVal;
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('\$${val.toInt()}', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Container(
                        width: 28,
                        height: 120 * pct,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Theme.of(context).colorScheme.primary,
                              Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                            ],
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                          borderRadius: BorderRadius.zero,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(day, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRevenue() {
    final cats = [
      {'name': 'Mains', 'pct': 0.60, 'color': Colors.blue},
      {'name': 'Starters', 'pct': 0.15, 'color': Colors.orange},
      {'name': 'Beverages', 'pct': 0.15, 'color': Colors.green},
      {'name': 'Desserts', 'pct': 0.10, 'color': Colors.purple},
    ];
    return BlockContainer(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Revenue by Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            ...cats.map((c) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(c['name'] as String, style: const TextStyle(fontSize: 12)),
                          Text('${((c['pct'] as double) * 100).toInt()}%', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.zero,
                        child: LinearProgressIndicator(
                          value: c['pct'] as double,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(c['color'] as Color),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTopDishes() {
    final items = [
      {'name': 'Truffle Mushroom Fettuccine', 'orders': 120, 'revenue': 2220.0, 'share': '32%'},
      {'name': 'Wood-Fired Pepperoni Pizza', 'orders': 95, 'revenue': 1520.0, 'share': '22%'},
      {'name': 'Fresh Mint Lime Mojito', 'orders': 80, 'revenue': 480.0, 'share': '18%'},
      {'name': 'Molten Chocolate Lava Cake', 'orders': 65, 'revenue': 552.0, 'share': '12%'},
    ];
    return BlockContainer(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Top Selling Dishes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('${item['orders']} orders (${item['share']} share)', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Text('\$${(item['revenue'] as double).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildTrafficHeatmap() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final slots = ['12 PM', '3 PM', '6 PM', '9 PM'];

    final matrix = [
      [2, 1, 3, 2],
      [2, 2, 3, 3],
      [3, 2, 4, 3],
      [2, 3, 4, 4],
      [3, 4, 5, 5],
      [4, 5, 5, 5],
      [4, 4, 5, 4],
    ];

    Color getHeatColor(int val) {
      switch (val) {
        case 1:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.15);
        case 2:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.35);
        case 3:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.55);
        case 4:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.75);
        case 5:
          return Theme.of(context).colorScheme.primary;
        default:
          return Theme.of(context).colorScheme.primary.withValues(alpha: 0.05);
      }
    }

    return BlockContainer(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Customer Traffic Heatmap', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 16),
            Row(
              children: [
                const SizedBox(width: 45),
                ...slots.map((s) => Expanded(
                      child: Text(s, style: const TextStyle(fontSize: 10, color: Colors.grey), textAlign: TextAlign.center),
                    )),
              ],
            ),
            const SizedBox(height: 8),
            ...List.generate(7, (dIdx) {
              final day = days[dIdx];
              final rowVals = matrix[dIdx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 45,
                      child: Text(day, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                    ...List.generate(4, (sIdx) {
                      final val = rowVals[sIdx];
                      return Expanded(
                        child: Container(
                          height: 24,
                          margin: const EdgeInsets.symmetric(horizontal: 2.0),
                          decoration: BoxDecoration(
                            color: getHeatColor(val),
                            borderRadius: BorderRadius.zero,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCoachView() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          // Business health and quick insights header card
          BlockContainer(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Icon(Icons.psychology, size: 40, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Business Health Score: 94/100',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Your margins look stable. Ask me questions below to discover optimizations.',
                          style: TextStyle(fontSize: 12, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Chat Area
          Expanded(
            child: BlockContainer(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(Icons.chat_bubble_outline, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        const Text('AI Business Coach Chat', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isAi = msg['role'] == 'ai';
                          return Align(
                            alignment: isAi ? Alignment.centerLeft : Alignment.centerRight,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isAi
                                    ? Colors.grey.shade100
                                    : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.4),
                                borderRadius: BorderRadius.zero,
                              ),
                              child: Text(msg['text'] as String),
                            ),
                          );
                        },
                      ),
                    ),
                    // Quick Prompt Suggestion Chips
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0, top: 4.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            ActionChip(
                              label: const Text('Least Profitable Dish?', style: TextStyle(fontSize: 11)),
                              onPressed: () => _sendSuggestion('Which dish is least profitable?'),
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('Reduce Food Waste?', style: TextStyle(fontSize: 11)),
                              onPressed: () => _sendSuggestion('How can I reduce waste?'),
                            ),
                            const SizedBox(width: 8),
                            ActionChip(
                              label: const Text('Forecast Weekend Revenue?', style: TextStyle(fontSize: 11)),
                              onPressed: () => _sendSuggestion('Forecast weekend revenue'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _chatController,
                            decoration: const InputDecoration(
                              hintText: 'Ask: "How can I reduce waste?" or "Peak hours"',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _sendMessage(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.send),
                          onPressed: _sendMessage,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      ],
                    )
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 2. KDS Tab Widget (Swimlanes layout)
// -------------------------------------------------------------
class _KdsTab extends ConsumerWidget {
  const _KdsTab();

  Color _getStatusColor(String status) {
    switch (status) {
      case 'placed':
        return Colors.red.shade400;
      case 'preparing':
        return Colors.orange.shade400;
      case 'out_for_delivery':
        return Colors.blue.shade400;
      default:
        return Colors.green.shade400;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersState = ref.watch(ownerOrdersProvider);
    final notifier = ref.read(ownerOrdersProvider.notifier);

    return ordersState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (orders) {
        final activeOrders = orders
            .where((o) => o.status != 'delivered' && o.status != 'cancelled')
            .toList();

        final width = MediaQuery.of(context).size.width;
        final isLarge = width >= 900;

        if (activeOrders.isEmpty) {
          return const Center(child: Text('No active orders in KDS.'));
        }

        // Split into lists based on status
        final newOrders = activeOrders.where((o) => o.status == 'placed').toList();
        final prepOrders = activeOrders.where((o) => o.status == 'preparing').toList();
        final readyOrders = activeOrders.where((o) => o.status == 'out_for_delivery').toList();

        if (isLarge) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(child: _kdsColumn(context, 'New Received', newOrders, notifier)),
                const SizedBox(width: 16),
                Expanded(child: _kdsColumn(context, 'Preparing / Cooking', prepOrders, notifier)),
                const SizedBox(width: 16),
                Expanded(child: _kdsColumn(context, 'Ready / Serving', readyOrders, notifier)),
              ],
            ),
          );
        } else {
          // List view on mobile
          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: activeOrders.length,
            itemBuilder: (context, index) => _kdsCard(context, activeOrders[index], notifier),
          );
        }
      },
    );
  }

  Widget _kdsColumn(BuildContext context, String title, List<OrderEntity> list, OwnerOrdersNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.zero,
          ),
          alignment: Alignment.center,
          child: Text(
            '$title (${list.length})',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) => _kdsCard(context, list[index], notifier),
          ),
        )
      ],
    );
  }

  Widget _kdsCard(BuildContext context, OrderEntity order, OwnerOrdersNotifier notifier) {
    return BlockContainer(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order #${order.id.substring(order.id.length - 4)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  order.status.toUpperCase(),
                  style: TextStyle(color: _getStatusColor(order.status), fontWeight: FontWeight.bold, fontSize: 10),
                ),
              ],
            ),
            const Divider(),
            ...order.items.map((i) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${i.quantity}x ${i.name}'),
                    ],
                  ),
                )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () => notifier.updateStatus(order.id, 'cancelled'),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Cancel'),
                ),
                TextButton.icon(
                  onPressed: () => _showInvoiceDialog(context, order),
                  icon: const Icon(Icons.receipt_long, size: 14),
                  label: const Text('Gen Bill', style: TextStyle(fontSize: 11)),
                ),
                if (order.status == 'placed')
                  ElevatedButton(
                    onPressed: () => notifier.updateStatus(order.id, 'preparing'),
                    child: const Text('Accept'),
                  ),
                if (order.status == 'preparing')
                  ElevatedButton(
                    onPressed: () => notifier.updateStatus(order.id, 'out_for_delivery'),
                    child: const Text('Cooked'),
                  ),
                if (order.status == 'out_for_delivery')
                  ElevatedButton(
                    onPressed: () => notifier.updateStatus(order.id, 'delivered'),
                    child: const Text('Served'),
                  ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// -------------------------------------------------------------
// 3. Table & POS Tab Widget
// -------------------------------------------------------------
class _TablePosTab extends ConsumerStatefulWidget {
  const _TablePosTab();

  @override
  ConsumerState<_TablePosTab> createState() => _TablePosTabState();
}

class _TablePosTabState extends ConsumerState<_TablePosTab> {
  TableState? _selectedTable;

  double _getDiscount(double subtotal, String code) {
    if (code.toUpperCase() == 'BISTRO20') return subtotal * 0.2;
    if (code.toUpperCase() == 'MIDWEEK10') return subtotal * 0.1;
    return 0.0;
  }

  void _showBillingSheet(TableState table) {
    final subtotal = table.activeOrderItems.fold<double>(0, (sum, i) => sum + i.price * i.quantity);
    final gst = subtotal * 0.18;
    final discountCodeController = TextEditingController();
    double discount = 0.0;
    String paymentMethod = 'card';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final total = subtotal + gst - discount;
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
              top: 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('POS Bill Checkout - ${table.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                    ],
                  ),
                  const Divider(),
                  ...table.activeOrderItems.map((i) => ListTile(
                        title: Text(i.name),
                        subtitle: Text('${i.quantity}x \$${i.price.toStringAsFixed(2)}'),
                        trailing: Text('\$${(i.price * i.quantity).toStringAsFixed(2)}'),
                      )),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal'),
                      Text('\$${subtotal.toStringAsFixed(2)}'),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('GST (18%)'),
                      Text('\$${gst.toStringAsFixed(2)}'),
                    ],
                  ),
                  if (discount > 0)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Discount Applied', style: TextStyle(color: Colors.green)),
                        Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.green)),
                      ],
                    ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: discountCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Coupon Code (e.g. BISTRO20)',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          setSheetState(() {
                            discount = _getDiscount(subtotal, discountCodeController.text.trim());
                          });
                        },
                        child: const Text('Apply'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: ['card', 'upi', 'cash', 'wallet']
                        .map((m) => DropdownMenuItem(value: m, child: Text(m.toUpperCase())))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setSheetState(() => paymentMethod = val);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Bill Payable', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('\$${total.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Theme.of(context).colorScheme.primary)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () async {
                      // Generate and complete order
                      final order = OrderEntity(
                        id: 'ord_pos_${DateTime.now().millisecondsSinceEpoch}',
                        customerId: 'pos_customer',
                        restaurantId: 'rest_456',
                        items: table.activeOrderItems,
                        subtotal: subtotal,
                        tax: gst,
                        deliveryFee: 0.0,
                        total: total,
                        status: 'delivered',
                        deliveryAddress: 'Table ${table.id}',
                        paymentMethod: paymentMethod,
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await ref.read(ownerOrdersProvider.notifier).addMockOrder(order);

                      // Clear table items & set available
                      setState(() {
                        table.status = 'available';
                        table.activeOrderItems = [];
                        _selectedTable = null;
                      });

                      if (!context.mounted) return;
                      Navigator.pop(context);

                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Invoice Printed'),
                          content: const Text('Digital Invoice generated & sent to POS thermal printer successfully!'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
                          ],
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                    child: const Text('Complete Payment & Print Bill'),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(tableStateProvider);

    return Scaffold(
      body: Row(
        children: [
          Expanded(
            flex: 3,
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.1,
              ),
              itemCount: tables.length,
              itemBuilder: (context, index) {
                final table = tables[index];
                final isSelected = _selectedTable?.id == table.id;
                Color tColor = Colors.green.shade400;
                if (table.status == 'occupied') tColor = Colors.red.shade400;
                if (table.status == 'reserved') tColor = Colors.blue.shade400;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedTable = table;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected ? tColor.withValues(alpha: 0.1) : Colors.grey.shade50,
                      border: Border.all(color: isSelected ? tColor : Colors.grey.shade300, width: isSelected ? 2 : 1),
                      borderRadius: BorderRadius.zero,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.table_restaurant, color: tColor, size: 28),
                        const SizedBox(height: 8),
                        Text(table.id, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Cap: ${table.capacity}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: tColor, borderRadius: BorderRadius.zero),
                          child: Text(table.status.toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedTable != null)
            Container(
              width: 300,
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: Colors.grey.shade300)),
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Table Details: ${_selectedTable!.id}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const SizedBox(height: 12),
                  Text('Capacity: ${_selectedTable!.capacity} Persons'),
                  Text('Current Status: ${_selectedTable!.status.toUpperCase()}'),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.qr_code_2, color: Colors.blue),
                    label: const Text('Digital Menu QR Code'),
                    onPressed: () => _showTableQrDialog(context, _selectedTable!),
                  ),
                  const Divider(),
                  if (_selectedTable!.status == 'occupied') ...[
                    const Text('Active Bill items:', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView.builder(
                        itemCount: _selectedTable!.activeOrderItems.length,
                        itemBuilder: (context, idx) {
                          final item = _selectedTable!.activeOrderItems[idx];
                          return Text('${item.quantity}x ${item.name} (\$${item.price.toStringAsFixed(2)})');
                        },
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.receipt_long),
                      label: const Text('Checkout / Print POS'),
                      onPressed: () => _showBillingSheet(_selectedTable!),
                    ),
                  ] else ...[
                    const Spacer(),
                    if (_selectedTable!.status == 'available')
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTable!.status = 'reserved';
                          });
                        },
                        child: const Text('Reserve Table'),
                      ),
                    if (_selectedTable!.status == 'reserved')
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _selectedTable!.status = 'available';
                          });
                        },
                        child: const Text('Cancel Reservation'),
                      ),
                    const SizedBox(height: 8),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _selectedTable!.status = 'occupied';
                          _selectedTable!.activeOrderItems = [
                            const CartItemEntity(itemId: 'menu_001', name: 'Truffle Mushroom Fettuccine', price: 18.50, quantity: 1, imageUrl: ''),
                          ];
                        });
                      },
                      child: const Text('Seat Guests (Seeded Pizza)'),
                    ),
                  ]
                ],
              ),
            )
        ],
      ),
    );
  }

  void _showTableQrDialog(BuildContext context, TableState table) {
    final authState = ref.read(authViewModelProvider);
    String shopName = 'Gourmet Bistro';
    if (authState is Authenticated) {
      try {
        final shop = FakeOwnerData.virtualShops.firstWhere(
          (s) => s.email.toLowerCase() == authState.user.email.toLowerCase(),
        );
        shopName = shop.shopName;
      } catch (_) {}
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Table Digital Menu QR Code', style: TextStyle(fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Place this print sticker on the table. Customers scan it with their phone to instantly view your digital menu and order.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.zero,
                border: Border.all(color: Colors.grey.shade400, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.restaurant_menu, color: Theme.of(context).colorScheme.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        shopName.toUpperCase(),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary, letterSpacing: 1.5),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: Colors.black12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qrCorner(),
                            _qrBlock(width: 30, height: 10),
                            _qrCorner(),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qrBlock(width: 20, height: 40),
                            _qrBlock(width: 40, height: 20),
                            _qrBlock(width: 15, height: 15),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _qrCorner(),
                            _qrBlock(width: 10, height: 20),
                            _qrBlock(width: 25, height: 25),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'TABLE ${table.id}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'SCAN TO ORDER',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.grey, letterSpacing: 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton.icon(
            icon: const Icon(Icons.download),
            label: const Text('Download PDF'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Downloading digital menu QR sticker PDF for Table ${table.id}...')),
              );
              Navigator.pop(context);
            },
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.print),
            label: const Text('Print Sticker'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Simulating sticker printing for Table ${table.id}...')),
              );
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _qrCorner() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black, width: 5),
      ),
      padding: const EdgeInsets.all(3),
      child: Container(
        color: Colors.black,
      ),
    );
  }

  Widget _qrBlock({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      color: Colors.black,
    );
  }
}

// -------------------------------------------------------------
// 4. Digital Menu Tab Widget
// -------------------------------------------------------------
// -------------------------------------------------------------
// 4. Digital Menu Tab Widget
// -------------------------------------------------------------
class _MenuEditorTab extends ConsumerStatefulWidget {
  const _MenuEditorTab();

  @override
  ConsumerState<_MenuEditorTab> createState() => _MenuEditorTabState();
}

class _MenuEditorTabState extends ConsumerState<_MenuEditorTab> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descController = TextEditingController();
  final _imageUrlController = TextEditingController();
  String _category = 'Mains';
  bool _isVeg = true;
  String _imageUrl = '';

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Widget _presetPhotoBubble(String label, String url, StateSetter setDialogState) {
    final isSelected = _imageUrl == url;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            setDialogState(() {
              _imageUrl = url;
              _imageUrlController.text = url;
            });
          }
        },
      ),
    );
  }

  void _showAddDialog() {
    _nameController.clear();
    _priceController.clear();
    _descController.clear();
    _imageUrlController.clear();
    _imageUrl = '';
    _category = 'Mains';
    _isVeg = true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      key: const Key('itemNameField'),
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('itemPriceField'),
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      key: const Key('itemDescField'),
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo Image URL',
                        hintText: 'Enter URL or tap preset below',
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          _imageUrl = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Preset Photos:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _presetPhotoBubble('Pizza 🍕', 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Pasta 🍝', 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Burger 🍔', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Salad 🥗', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Cake 🍰', 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Drink 🍹', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80', setDialogState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['Starters', 'Mains', 'Desserts', 'Beverages']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Vegetarian'),
                      value: _isVeg,
                      onChanged: (val) {
                        setDialogState(() => _isVeg = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  key: const Key('saveItemButton'),
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    final desc = _descController.text.trim();

                    if (name.isNotEmpty && price > 0) {
                      final item = MenuItemEntity(
                        id: 'menu_${DateTime.now().millisecondsSinceEpoch}',
                        restaurantId: 'rest_456',
                        name: name,
                        description: desc,
                        price: price,
                        category: _category,
                        isVegetarian: _isVeg,
                        imageUrl: _imageUrl,
                      );
                      
                      ref.read(menuViewModelProvider.notifier).addItemToMockList(item);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item added successfully!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditDialog(MenuItemEntity item) {
    _nameController.text = item.name;
    _priceController.text = item.price.toString();
    _descController.text = item.description;
    _imageUrlController.text = item.imageUrl;
    _imageUrl = item.imageUrl;
    _category = item.category;
    _isVeg = item.isVegetarian;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Menu Item'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Item Name'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _priceController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Price'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _descController,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _imageUrlController,
                      decoration: const InputDecoration(
                        labelText: 'Photo Image URL',
                        hintText: 'Enter URL or tap preset below',
                      ),
                      onChanged: (val) {
                        setDialogState(() {
                          _imageUrl = val.trim();
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Preset Photos:', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _presetPhotoBubble('Pizza 🍕', 'https://images.unsplash.com/photo-1628840042765-356cda07504e?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Pasta 🍝', 'https://images.unsplash.com/photo-1645112411341-6c4fd023714a?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Burger 🍔', 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Salad 🥗', 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Cake 🍰', 'https://images.unsplash.com/photo-1606313564200-e75d5e30476c?auto=format&fit=crop&w=400&q=80', setDialogState),
                        _presetPhotoBubble('Drink 🍹', 'https://images.unsplash.com/photo-1513558161293-cdaf765ed2fd?auto=format&fit=crop&w=400&q=80', setDialogState),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: ['Starters', 'Mains', 'Desserts', 'Beverages']
                          .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() => _category = val);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Vegetarian'),
                      value: _isVeg,
                      onChanged: (val) {
                        setDialogState(() => _isVeg = val);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = _nameController.text.trim();
                    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;
                    final desc = _descController.text.trim();

                    if (name.isNotEmpty && price > 0) {
                      final updatedItem = MenuItemEntity(
                        id: item.id,
                        restaurantId: item.restaurantId,
                        name: name,
                        description: desc,
                        price: price,
                        category: _category,
                        isVegetarian: _isVeg,
                        imageUrl: _imageUrl,
                      );
                      
                      ref.read(menuViewModelProvider.notifier).updateItemInMockList(updatedItem);
                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Item updated successfully!')),
                      );
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('addMenuItemButton'),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: menuState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (items) {
          if (items.isEmpty) {
            return const Center(child: Text('No menu items. Add one!'));
          }

          return ListView.builder(
            padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];

              return BlockContainer(
                child: ListTile(
                  leading: item.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.zero,
                          child: Image.network(
                            item.imageUrl,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Icon(Icons.fastfood),
                          ),
                        )
                      : const Icon(Icons.fastfood),
                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('\$${item.price.toStringAsFixed(2)} • ${item.category}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: item.isVegetarian ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                        onPressed: () => _showEditDialog(item),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () {
                          ref.read(menuViewModelProvider.notifier).removeItemFromMockList(item.id);
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// -------------------------------------------------------------
// 5. Staff & Inventory Tab Widget
// -------------------------------------------------------------
class _StaffInventoryTab extends ConsumerStatefulWidget {
  const _StaffInventoryTab();

  @override
  ConsumerState<_StaffInventoryTab> createState() => _StaffInventoryTabState();
}

class _StaffInventoryTabState extends ConsumerState<_StaffInventoryTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final List<InventoryItem> _inventory = List.from(FakeOwnerData.initialInventory);
  List<StaffProfile> _staffList = [];
  final Map<String, String> _attendance = {};

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
    _loadStaffForShop();
  }

  void _loadStaffForShop() {
    final authState = ref.read(authViewModelProvider);
    int staffCount = FakeOwnerData.staff.length;
    if (authState is Authenticated) {
      final email = authState.user.email;
      try {
        final shop = FakeOwnerData.virtualShops.firstWhere(
          (s) => s.email.toLowerCase() == email.toLowerCase(),
        );
        staffCount = shop.staffQuantity;
      } catch (_) {}
    }
    
    _staffList = FakeOwnerData.staff.take(staffCount).toList();
    for (var member in _staffList) {
      _attendance[member.id] = member.isPresent ? 'Present' : 'Absent';
    }
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '📦 Inventory Stock'),
              Tab(text: '👨💼 Staff Members'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          // Inventory Sub-Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _inventory.length,
            itemBuilder: (context, index) {
              final item = _inventory[index];
              return BlockContainer(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      Icon(Icons.inventory, color: item.isLowStock ? Colors.red : Colors.grey, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text('Supplier: ${item.supplierName} • Expiry: ${item.expiryDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(
                              value: item.currentStock / 200,
                              color: item.isLowStock ? Colors.red : Colors.green,
                              backgroundColor: Colors.grey.shade200,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Column(
                        children: [
                          Text('${item.currentStock} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (item.isLowStock)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.zero),
                              child: const Text('LOW STOCK', style: TextStyle(color: Colors.red, fontSize: 8, fontWeight: FontWeight.bold)),
                            )
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          // Staff Sub-Tab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _staffList.length,
            itemBuilder: (context, index) {
              final member = _staffList[index];
              final status = _attendance[member.id] ?? 'Absent';
              
              Color statusColor = Colors.green;
              Color bgStatusColor = Colors.green.shade50;
              Color borderStatusColor = Colors.green.shade200;
              if (status == 'Absent') {
                statusColor = Colors.red.shade800;
                bgStatusColor = Colors.red.shade50;
                borderStatusColor = Colors.red.shade200;
              } else if (status == 'On Leave') {
                statusColor = Colors.orange.shade800;
                bgStatusColor = Colors.orange.shade50;
                borderStatusColor = Colors.orange.shade200;
              } else {
                statusColor = Colors.green.shade800;
              }

              return BlockContainer(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    child: Text(member.name[0]),
                  ),
                  title: Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${member.role} • Shift: ${member.shift}'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: bgStatusColor,
                      borderRadius: BorderRadius.zero,
                      border: Border.all(color: borderStatusColor),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: status,
                        icon: const Icon(Icons.arrow_drop_down, size: 16),
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                        onChanged: (newVal) {
                          if (newVal != null) {
                            setState(() {
                              _attendance[member.id] = newVal;
                            });
                          }
                        },
                        items: const [
                          DropdownMenuItem(value: 'Present', child: Text('Present')),
                          DropdownMenuItem(value: 'Absent', child: Text('Absent')),
                          DropdownMenuItem(value: 'On Leave', child: Text('On Leave')),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 6. Promos & Social Feed Tab Widget
// -------------------------------------------------------------
class _PromoSocialTab extends StatefulWidget {
  const _PromoSocialTab();

  @override
  State<_PromoSocialTab> createState() => _PromoSocialTabState();
}

class _PromoSocialTabState extends State<_PromoSocialTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final List<Promotion> _promotions = List.from(FakeOwnerData.promotions);
  final List<SocialFeedItem> _socialFeed = List.from(FakeOwnerData.socialFeed);

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _showAddCouponDialog() {
    final codeController = TextEditingController();
    final descController = TextEditingController();
    final discountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Offer Coupon'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: codeController, decoration: const InputDecoration(labelText: 'Coupon Code (e.g. SUMMER30)')),
            TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description')),
            TextField(controller: discountController, decoration: const InputDecoration(labelText: 'Discount %'), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final code = codeController.text.trim();
              final desc = descController.text.trim();
              final discount = double.tryParse(discountController.text.trim()) ?? 0.0;
              if (code.isNotEmpty && discount > 0) {
                setState(() {
                  _promotions.add(Promotion(
                    id: 'promo_${DateTime.now().millisecondsSinceEpoch}',
                    code: code,
                    description: desc,
                    discountPercent: discount,
                    isActive: true,
                    expiryDate: '2026-12-31',
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Save Offer'),
          )
        ],
      ),
    );
  }

  void _showAddPostDialog() {
    final titleController = TextEditingController();
    String mediaType = 'video'; // 'video' or 'image'

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Publish Reel / Feed Post'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Post Caption / Title',
                    hintText: 'e.g. Try our sizzling Arrabiata pasta!',
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Media Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('🎥 Reel (Video)'),
                      selected: mediaType == 'video',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => mediaType = 'video');
                      },
                    ),
                    const SizedBox(width: 12),
                    ChoiceChip(
                      label: const Text('🖼️ Feed Post (Image)'),
                      selected: mediaType == 'image',
                      onSelected: (selected) {
                        if (selected) setDialogState(() => mediaType = 'image');
                      },
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final title = titleController.text.trim();
                  if (title.isNotEmpty) {
                    setState(() {
                      _socialFeed.insert(0, SocialFeedItem(
                        id: 'soc_${DateTime.now().millisecondsSinceEpoch}',
                        title: title,
                        mediaType: mediaType,
                        views: 0,
                        likes: 0,
                        commentsCount: 0,
                        uploadDate: DateTime.now().toString().split(' ')[0],
                      ));
                    });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reel/Post published successfully!')),
                    );
                  }
                },
                child: const Text('Publish'),
              )
            ],
          );
        }
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '🎁 Discount Coupons'),
              Tab(text: '🎥 Reels & Feed Media'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          // Coupons Sub-Tab
          Scaffold(
            floatingActionButton: FloatingActionButton(
              onPressed: _showAddCouponDialog,
              child: const Icon(Icons.add),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _promotions.length,
              itemBuilder: (context, index) {
                final promo = _promotions[index];
                return BlockContainer(
                  child: ListTile(
                    leading: const Icon(Icons.local_offer, color: Colors.purple),
                    title: Text(promo.code, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${promo.description}\nExpiry: ${promo.expiryDate}'),
                    trailing: Text('${promo.discountPercent.toInt()}% OFF', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.purple)),
                  ),
                );
              },
            ),
          ),
          // Reels / Social Feed Sub-Tab
          Scaffold(
            floatingActionButton: FloatingActionButton(
              key: const Key('addPostButton'),
              onPressed: _showAddPostDialog,
              child: const Icon(Icons.add),
            ),
            body: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _socialFeed.length,
              itemBuilder: (context, index) {
                final post = _socialFeed[index];
                return BlockContainer(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.zero,
                          ),
                          child: Icon(post.mediaType == 'video' ? Icons.play_circle_outline : Icons.image, size: 36),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(post.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('Uploaded: ${post.uploadDate}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${post.views}', style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.favorite_border, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${post.likes}', style: const TextStyle(fontSize: 11)),
                                  const SizedBox(width: 12),
                                  Icon(Icons.chat_bubble_outline, size: 14, color: Colors.grey.shade600),
                                  const SizedBox(width: 4),
                                  Text('${post.commentsCount}', style: const TextStyle(fontSize: 11)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 7. Customers & Reviews Tab Widget
// -------------------------------------------------------------
class _CustomerReviewsTab extends StatefulWidget {
  const _CustomerReviewsTab();

  @override
  State<_CustomerReviewsTab> createState() => _CustomerReviewsTabState();
}

class _CustomerReviewsTabState extends State<_CustomerReviewsTab> with SingleTickerProviderStateMixin {
  late TabController _subTabController;
  final List<CustomerFeedbackModel> _feedbacks = List.from(FakeOwnerData.initialFeedback);

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  void _showReplyDialog(CustomerFeedbackModel fb) {
    final replyController = TextEditingController(text: fb.reply);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${fb.customerName}'),
        content: TextField(
          controller: replyController,
          maxLines: 3,
          decoration: const InputDecoration(hintText: 'Enter your response...', border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                fb.reply = replyController.text.trim();
              });
              Navigator.pop(context);
            },
            child: const Text('Save Reply'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(48),
        child: Align(
          alignment: Alignment.centerLeft,
          child: TabBar(
            controller: _subTabController,
            isScrollable: true,
            tabs: const [
              Tab(text: '👥 Customer Loyalty'),
              Tab(text: '⭐ Reviews & Replies'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _subTabController,
        children: [
          // Loyalty subtab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: FakeOwnerData.customers.length,
            itemBuilder: (context, index) {
              final cust = FakeOwnerData.customers[index];
              return BlockContainer(
                child: ListTile(
                  leading: CircleAvatar(child: Text(cust.name[0])),
                  title: Text(cust.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('${cust.email} • Total Orders: ${cust.totalOrders}'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(color: Colors.amber.shade600, borderRadius: BorderRadius.zero),
                        child: Text(cust.tier, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 4),
                      Text('${cust.loyaltyPoints} pts', style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              );
            },
          ),
          // Reviews subtab
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _feedbacks.length,
            itemBuilder: (context, index) {
              final fb = _feedbacks[index];
              return BlockContainer(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(fb.customerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                          Row(
                            children: List.generate(5, (starIdx) => Icon(
                              Icons.star,
                              color: starIdx < fb.rating ? Colors.amber : Colors.grey.shade300,
                              size: 16,
                            )),
                          )
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(fb.comment, style: const TextStyle(fontSize: 12)),
                      if (fb.reply != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          width: double.infinity,
                          decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.zero),
                          child: Text('Owner Reply: ${fb.reply}', style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic)),
                        )
                      ],
                      const Divider(),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed: () => _showReplyDialog(fb),
                          icon: const Icon(Icons.reply),
                          label: Text(fb.reply != null ? 'Edit Reply' : 'Send Reply'),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

// -------------------------------------------------------------
// 8. Console Settings Tab Widget
// -------------------------------------------------------------
class _SettingsTab extends ConsumerStatefulWidget {
  const _SettingsTab();

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  bool _is2faActive = true;
  final String _hoursStart = '08:00 AM';
  final String _hoursEnd = '10:00 PM';
  double _gstRate = 18.0;

  void _showCreateShopDialog() {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final idCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final pwdCtrl = TextEditingController();
    int capacity = 6;
    int staff = 4;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          title: const Text('Create New Virtual Shop'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Name (e.g. My Pizza Grill)'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: idCtrl,
                    decoration: const InputDecoration(labelText: 'Shop Code ID (e.g. PIZZA-01)'),
                    validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: emailCtrl,
                    decoration: const InputDecoration(labelText: 'Login Email Address'),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Invalid Email' : null,
                  ),
                  TextFormField(
                    controller: pwdCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Login Password'),
                    validator: (v) => (v == null || v.length < 4) ? 'Too short' : null,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Table Capacity: $capacity'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: capacity > 1 ? () => setDlgState(() => capacity--) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setDlgState(() => capacity++),
                          ),
                        ],
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Staff Quantity: $staff'),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove),
                            onPressed: staff > 1 ? () => setDlgState(() => staff--) : null,
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () => setDlgState(() => staff++),
                          ),
                        ],
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final newShop = VirtualShop(
                    shopId: idCtrl.text.trim(),
                    shopName: nameCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: pwdCtrl.text,
                    tableCapacity: capacity,
                    staffQuantity: staff,
                  );
                  FakeOwnerData.virtualShops.add(newShop);
                  setState(() {});
                  Navigator.pop(context);

                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Virtual Shop Created!'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Shop Name: ${newShop.shopName}'),
                          Text('Shop ID: ${newShop.shopId}'),
                          const Divider(),
                          const Text('Owner Credentials to Log In:', style: TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          SelectableText('Email: ${newShop.email}'),
                          SelectableText('Password: ${newShop.password}'),
                          const SizedBox(height: 12),
                          const Text('Logout and type these credentials on the sign-in page to launch this virtual shop console.', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        )
                      ],
                    ),
                  );
                }
              },
              child: const Text('Create Shop'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditCapacityDialog(VirtualShop shop) {
    final capCtrl = TextEditingController(text: '${shop.tableCapacity}');
    final staffCtrl = TextEditingController(text: '${shop.staffQuantity}');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Capacity: ${shop.shopName}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: capCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Table Capacity (Max Seating tables)'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: staffCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Staff Quantity (Active Roster size)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final newCap = int.tryParse(capCtrl.text.trim());
              final newStaff = int.tryParse(staffCtrl.text.trim());
              if (newCap != null && newCap > 0 && newStaff != null && newStaff > 0) {
                shop.tableCapacity = newCap;
                shop.staffQuantity = newStaff;
                
                final currentTables = ref.read(tableStateProvider);
                if (currentTables.length != newCap) {
                  if (newCap > currentTables.length) {
                    final added = List.generate(newCap - currentTables.length, (idx) {
                      final idNum = currentTables.length + idx + 1;
                      return TableState(
                        id: 'T-${idNum.toString().padLeft(2, '0')}',
                        capacity: 4,
                        status: 'available',
                      );
                    });
                    ref.read(tableStateProvider.notifier).state = [...currentTables, ...added];
                  } else {
                    ref.read(tableStateProvider.notifier).state = currentTables.take(newCap).toList();
                  }
                }
                
                setState(() {});
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Updated capacity configuration for ${shop.shopName}')),
                );
              }
            },
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    VirtualShop? activeShop;
    if (authState is Authenticated) {
      try {
        activeShop = FakeOwnerData.virtualShops.firstWhere(
          (s) => s.email.toLowerCase() == authState.user.email.toLowerCase(),
        );
      } catch (_) {}
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (activeShop != null)
          BlockContainer(
            color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.15),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(activeShop.shopName, style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 18), overflow: TextOverflow.ellipsis),
                            Text('Active Shop ID: ${activeShop.shopId}', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                          ],
                        ),
                      ),
                      IconButton.filledTonal(
                        icon: const Icon(Icons.edit_note),
                        onPressed: () => _showEditCapacityDialog(activeShop!),
                      ),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text('${activeShop.tableCapacity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const Text('Table Capacity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        children: [
                          Text('${activeShop.staffQuantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                          const Text('Staff Quantity', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 12),
        BlockContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Restaurant Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                ListTile(
                  title: const Text('Store Operating Hours'),
                  subtitle: Text('$_hoursStart - $_hoursEnd'),
                  trailing: const Icon(Icons.edit),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Hours'),
                        content: const Text('Select operating time configuration. (Simulated)'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                        ],
                      ),
                    );
                  },
                ),
                ListTile(
                  title: const Text('Tax Configuration (GST)'),
                  subtitle: Text('${_gstRate.toInt()}% standard tax applied at checkout POS'),
                  trailing: const Icon(Icons.tune),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Change Tax Rate'),
                        content: TextField(
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(labelText: 'GST Percent'),
                          onChanged: (val) {
                            final parsed = double.tryParse(val);
                            if (parsed != null && parsed >= 0) {
                              setState(() {
                                _gstRate = parsed;
                              });
                            }
                          },
                        ),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Save'))
                        ],
                      ),
                    );
                  },
                )
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        BlockContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Virtual Shops & Branches', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('New Shop', style: TextStyle(fontSize: 12)),
                      onPressed: _showCreateShopDialog,
                    ),
                  ],
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: FakeOwnerData.virtualShops.length,
                  itemBuilder: (context, idx) {
                    final shop = FakeOwnerData.virtualShops[idx];
                    final isActive = shop.shopId == activeShop?.shopId;
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.storefront, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey),
                      title: Text(shop.shopName, style: TextStyle(fontWeight: isActive ? FontWeight.bold : FontWeight.normal)),
                      subtitle: Text('Email: ${shop.email} | Pwd: ${shop.password}'),
                      trailing: Text('${shop.tableCapacity} Tabs / ${shop.staffQuantity} Staff', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        BlockContainer(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Security settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const Divider(),
                SwitchListTile(
                  title: const Text('Two-Factor Authentication (2FA)'),
                  subtitle: const Text('Protect Owner panel from unauthorized terminal access'),
                  value: _is2faActive,
                  onChanged: (val) {
                    setState(() {
                      _is2faActive = val;
                    });
                  },
                ),
                ListTile(
                  title: const Text('Owner Login History Log'),
                  subtitle: const Text('Last log in: Today at 01:50 AM from Chrome Web Console'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                )
              ],
            ),
          ),
        )
      ],
    );
  }
}

// -------------------------------------------------------------
// Helper Notification bell badge widget
// -------------------------------------------------------------
class _NotificationBellWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.notifications),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Alerts & Notifications'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(leading: const Icon(Icons.shopping_bag, color: Colors.orange), title: const Text('New Customer Table Order'), subtitle: const Text('Table T-01 placed order for Pepperoni Pizza')),
                    ListTile(leading: const Icon(Icons.inventory, color: Colors.red), title: const Text('Low Stock Alert'), subtitle: const Text('Flour stock dropped below minimum threshold.')),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 8,
          top: 8,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
            constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
            child: const Text('2', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ),
        )
      ],
    );
  }
}

void _showInvoiceDialog(BuildContext context, OrderEntity order) {
  final subtotal = order.subtotal;
  final gst = order.tax;
  final discount = order.discount;
  final grandTotal = order.total;

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Gourmet Bistro Invoice', style: TextStyle(fontWeight: FontWeight.bold)),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('GSTIN: 27AAAAA1111A1Z1', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Text('Main Branch, Gourmet Ave', style: TextStyle(fontSize: 10, color: Colors.grey)),
            const Divider(),
            Text('Invoice #: INV-${order.id.substring(order.id.length - 4).toUpperCase()}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            Text('Date: ${order.createdAt.toLocal().toString().split('.')[0]}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            Text('Location: ${order.deliveryAddress}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const Divider(),
            const SizedBox(height: 8),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: Text('Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                SizedBox(width: 12),
                Text('Qty', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                SizedBox(width: 24),
                Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ],
            ),
            const SizedBox(height: 8),
            ...order.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(item.name, style: const TextStyle(fontSize: 12))),
                  const SizedBox(width: 12),
                  Text('${item.quantity}', style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 24),
                  Text('\$${(item.price * item.quantity).toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            )),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal', style: TextStyle(fontSize: 12)),
                Text('\$${subtotal.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('GST (18%)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                Text('\$${gst.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
            if (order.deliveryFee > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery Fee', style: TextStyle(fontSize: 12)),
                  Text('\$${order.deliveryFee.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12)),
                ],
              ),
            if (discount > 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Discount Applied', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                  Text('-\$${discount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                ],
              ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Grand Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                Text('\$${grandTotal.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Theme.of(context).colorScheme.primary)),
              ],
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                '--- Thank You for Dining with Us ---',
                style: TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
              ),
            )
          ],
        ),
      ),
      actions: [
        OutlinedButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Simulating receipt print...')),
            );
            Navigator.pop(context);
          },
          icon: const Icon(Icons.print),
          label: const Text('Print Receipt'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}
