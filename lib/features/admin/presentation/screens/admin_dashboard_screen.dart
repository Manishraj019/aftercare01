import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class Restaurant {
  final String id;
  final String name;
  final String address;
  final String cuisine;
  final String licenseStatus; // 'active', 'suspended'

  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    required this.cuisine,
    required this.licenseStatus,
  });

  Restaurant copyWith({String? licenseStatus}) {
    return Restaurant(
      id: id,
      name: name,
      address: address,
      cuisine: cuisine,
      licenseStatus: licenseStatus ?? this.licenseStatus,
    );
  }
}

class SystemUser {
  final String name;
  final String email;
  final String role; // 'admin', 'owner', 'customer'

  const SystemUser({required this.name, required this.email, required this.role});
}

class AdminState {
  final List<Restaurant> restaurants;
  final List<SystemUser> users;

  const AdminState({required this.restaurants, required this.users});

  AdminState copyWith({List<Restaurant>? restaurants, List<SystemUser>? users}) {
    return AdminState(
      restaurants: restaurants ?? this.restaurants,
      users: users ?? this.users,
    );
  }
}

// Riverpod Provider for Admin Dashboard State
final adminViewModelProvider = StateNotifierProvider<AdminViewModel, AdminState>((ref) {
  return AdminViewModel();
});

class AdminViewModel extends StateNotifier<AdminState> {
  AdminViewModel()
      : super(
          const AdminState(
            restaurants: [
              Restaurant(
                id: 'rest_456',
                name: 'Gourmet Bistro',
                address: '123 Gourmet Ave, Foodtown',
                cuisine: 'Italian / Fine Dining',
                licenseStatus: 'active',
              ),
              Restaurant(
                id: 'rest_789',
                name: 'Seafood Cove',
                address: '456 Harbour Dr, Seatown',
                cuisine: 'Seafood',
                licenseStatus: 'active',
              ),
              Restaurant(
                id: 'rest_012',
                name: 'Tuscan Pizzeria',
                address: '789 Napoli Way, Pastaland',
                cuisine: 'Pizza',
                licenseStatus: 'suspended',
              ),
            ],
            users: [
              SystemUser(name: 'Platform Operator', email: 'admin@restaurantos.com', role: 'admin'),
              SystemUser(name: 'Bistro Chef Owner', email: 'owner@restaurantos.com', role: 'owner'),
              SystemUser(name: 'Regular Customer', email: 'customer@restaurantos.com', role: 'customer'),
            ],
          ),
        );

  void addRestaurant(Restaurant rest) {
    state = state.copyWith(restaurants: [...state.restaurants, rest]);
  }

  void toggleLicense(String id) {
    state = state.copyWith(
      restaurants: state.restaurants.map((r) {
        if (r.id == id) {
          final nextStatus = r.licenseStatus == 'active' ? 'suspended' : 'active';
          return r.copyWith(licenseStatus: nextStatus);
        }
        return r;
      }).toList(),
    );
  }
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.business), text: 'Restaurants'),
            Tab(icon: Icon(Icons.vpn_key), text: 'Licensing'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _RestaurantsTab(),
          const _LicensingTab(),
          const _UsersTab(),
        ],
      ),
    );
  }
}

// 1. Restaurants Tab
class _RestaurantsTab extends ConsumerStatefulWidget {
  const _RestaurantsTab();

  @override
  ConsumerState<_RestaurantsTab> createState() => _RestaurantsTabState();
}

class _RestaurantsTabState extends ConsumerState<_RestaurantsTab> {
  final _nameController = TextEditingController();
  final _addrController = TextEditingController();
  final _cuisineController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _addrController.dispose();
    _cuisineController.dispose();
    super.dispose();
  }

  void _showAddDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Register Restaurant'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                key: const Key('restNameField'),
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Restaurant Name'),
              ),
              TextField(
                key: const Key('restAddrField'),
                controller: _addrController,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              TextField(
                key: const Key('restCuisineField'),
                controller: _cuisineController,
                decoration: const InputDecoration(labelText: 'Cuisine Style'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              key: const Key('saveRestButton'),
              onPressed: () {
                final name = _nameController.text.trim();
                final addr = _addrController.text.trim();
                final cuisine = _cuisineController.text.trim();

                if (name.isNotEmpty && addr.isNotEmpty) {
                  final rest = Restaurant(
                    id: 'rest_${DateTime.now().millisecondsSinceEpoch}',
                    name: name,
                    address: addr,
                    cuisine: cuisine,
                    licenseStatus: 'active',
                  );

                  ref.read(adminViewModelProvider.notifier).addRestaurant(rest);

                  _nameController.clear();
                  _addrController.clear();
                  _cuisineController.clear();
                  Navigator.pop(context);

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Restaurant registered successfully!')),
                  );
                }
              },
              child: const Text('Register'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminViewModelProvider);

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        key: const Key('addRestaurantButton'),
        onPressed: _showAddDialog,
        child: const Icon(Icons.add),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 80.0),
        itemCount: state.restaurants.length,
        itemBuilder: (context, index) {
          final rest = state.restaurants[index];

          return Card(
            child: ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.restaurant, color: Theme.of(context).colorScheme.primary),
              ),
              title: Text(rest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${rest.cuisine} • ${rest.address}'),
              trailing: Chip(
                label: Text(
                  rest.licenseStatus.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: rest.licenseStatus == 'active' ? Colors.green : Colors.red,
                  ),
                ),
                backgroundColor: rest.licenseStatus == 'active' ? Colors.green.shade50 : Colors.red.shade50,
                side: BorderSide.none,
              ),
            ),
          );
        },
      ),
    );
  }
}

// 2. Licensing Tab
class _LicensingTab extends ConsumerWidget {
  const _LicensingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);
    final notifier = ref.read(adminViewModelProvider.notifier);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.restaurants.length,
      itemBuilder: (context, index) {
        final rest = state.restaurants[index];
        final isActive = rest.licenseStatus == 'active';

        return Card(
          child: ListTile(
            title: Text(rest.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(isActive ? 'Status: Active Licence' : 'Status: Suspended Licence'),
            trailing: Switch(
              key: Key('lic_switch_${rest.id}'),
              value: isActive,
              activeThumbColor: Colors.green,
              inactiveTrackColor: Colors.red.shade100,
              onChanged: (_) {
                notifier.toggleLicense(rest.id);
              },
            ),
          ),
        );
      },
    );
  }
}

// 3. Users Tab
class _UsersTab extends ConsumerWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminViewModelProvider);

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: state.users.length,
      itemBuilder: (context, index) {
        final user = state.users[index];

        return Card(
          child: ListTile(
            leading: Icon(
              user.role == 'admin'
                  ? Icons.admin_panel_settings
                  : user.role == 'owner'
                      ? Icons.business_center
                      : Icons.person,
              color: user.role == 'admin'
                  ? Colors.purple
                  : user.role == 'owner'
                      ? Colors.teal
                      : Colors.grey,
            ),
            title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(user.email),
            trailing: Chip(
              label: Text(
                user.role.toUpperCase(),
                style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold),
              ),
              side: BorderSide.none,
            ),
          ),
        );
      },
    );
  }
}
