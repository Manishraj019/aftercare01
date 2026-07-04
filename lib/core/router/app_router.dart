import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurantos/features/auth/presentation/screens/login_screen.dart';
import 'package:restaurantos/features/auth/presentation/screens/register_screen.dart';
import 'package:restaurantos/features/auth/presentation/screens/otp_screen.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';

import 'package:restaurantos/features/menu/presentation/screens/menu_screen.dart';
import 'package:restaurantos/features/menu/presentation/screens/cart_screen.dart';
import 'package:restaurantos/features/orders/presentation/screens/checkout_screen.dart';
import 'package:restaurantos/features/orders/presentation/screens/order_history_screen.dart';

import 'package:restaurantos/features/menu/presentation/screens/customer_landing_screen.dart';
import 'package:restaurantos/features/owner/presentation/screens/owner_dashboard_screen.dart';
import 'package:restaurantos/features/admin/presentation/screens/admin_dashboard_screen.dart';

// GoRouter provider to make routing reactive and injectable
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return RegisterScreen(initialRole: role);
        },
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) => const OtpScreen(),
      ),
      GoRoute(
        path: '/customer',
        builder: (context, state) => const CustomerLandingScreen(),
      ),
      GoRoute(
        path: '/customer/menu',
        builder: (context, state) => const MenuScreen(),
      ),
      GoRoute(
        path: '/customer/cart',
        builder: (context, state) => const CartScreen(),
      ),
      GoRoute(
        path: '/customer/checkout',
        builder: (context, state) => const CheckoutScreen(),
      ),
      GoRoute(
        path: '/customer/orders',
        builder: (context, state) => const OrderHistoryScreen(),
      ),
      GoRoute(
        path: '/owner',
        builder: (context, state) => const OwnerDashboardScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Page not found'),
      ),
    ),
  );
});

// Simple placeholder screens for initial routing setup
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Warm up the provider to trigger checkCurrentUser immediately on startup
    ref.read(authViewModelProvider);
    _startRedirectTimer();
  }

  void _startRedirectTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final authState = ref.read(authViewModelProvider);
        debugPrint('SPLASH REDIRECT: authState is $authState');
        if (authState is Authenticated) {
          final role = authState.user.role;
          if (role == 'admin') {
            context.go('/admin');
          } else if (role == 'owner') {
            context.go('/owner');
          } else {
            context.go('/customer');
          }
        } else {
          context.go('/login');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant,
                size: 64,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'RestaurantOS',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            const SizedBox(
              width: 150,
              child: LinearProgressIndicator(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreenPlaceholder extends StatelessWidget {
  const LoginScreenPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Welcome to\nRestaurantOS',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                      fontSize: 32,
                      height: 1.2,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Select your workspace role to begin',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 48),
              ElevatedButton.icon(
                icon: const Icon(Icons.person),
                label: const Text('Customer App'),
                onPressed: () => context.go('/customer'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.storefront),
                label: const Text('Restaurant Owner Panel'),
                onPressed: () => context.go('/owner'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Super Admin Panel'),
                onPressed: () => context.go('/admin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerDashboardPlaceholder extends StatelessWidget {
  const CustomerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Customer Ordering, Discovery & Reels Screen'),
      ),
    );
  }
}

class OwnerDashboardPlaceholder extends StatelessWidget {
  const OwnerDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Owner OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Menu, Inventory, Staff & KDS Management Screen'),
      ),
    );
  }
}

class AdminDashboardPlaceholder extends StatelessWidget {
  const AdminDashboardPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Super Admin OS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: const Center(
        child: Text('Platform oversight & Super Admin Analytics Screen'),
      ),
    );
  }
}
