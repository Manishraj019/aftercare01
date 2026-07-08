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
import 'package:restaurantos/features/landing/presentation/screens/landing_screen.dart';

// Smooth Fade Transition Helper
Page _fadeTransitionPage(BuildContext context, GoRouterState state, Widget child) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurveTween(curve: Curves.easeInOut).animate(animation),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 400),
  );
}

// GoRouter provider to make routing reactive and injectable
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const LandingScreen()),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: '/register',
        pageBuilder: (context, state) {
          final role = state.uri.queryParameters['role'];
          return _fadeTransitionPage(context, state, RegisterScreen(initialRole: role));
        },
      ),
      GoRoute(
        path: '/otp',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const OtpScreen()),
      ),
      GoRoute(
        path: '/customer',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const CustomerLandingScreen()),
      ),
      GoRoute(
        path: '/customer/menu',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const MenuScreen()),
      ),
      GoRoute(
        path: '/customer/cart',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const CartScreen()),
      ),
      GoRoute(
        path: '/customer/checkout',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const CheckoutScreen()),
      ),
      GoRoute(
        path: '/customer/orders',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const OrderHistoryScreen()),
      ),
      GoRoute(
        path: '/owner',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const OwnerDashboardScreen()),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => _fadeTransitionPage(context, state, const AdminDashboardScreen()),
      ),
    ],
    errorBuilder: (context, state) => const Scaffold(
      body: Center(
        child: Text('Page not found'),
      ),
    ),
  );
});

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(authViewModelProvider);
    _startRedirectTimer();
  }

  void _startRedirectTimer() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        final authState = ref.read(authViewModelProvider);
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
      backgroundColor: Theme.of(context).colorScheme.primary, // Bold Red Background
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onPrimary, // White block
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 4), // Dark border
                boxShadow: const [
                  BoxShadow(color: Colors.black26, offset: Offset(8, 8)),
                ],
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 48),
            Text(
              'RESTAURANT',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    letterSpacing: 4,
                  ),
            ),
            Text(
              'OS',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                    letterSpacing: 2,
                  ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                backgroundColor: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.3),
                color: Theme.of(context).colorScheme.secondary,
                minHeight: 8,
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
      body: Row(
        children: [
          // Left side brand block
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).colorScheme.primary,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(48.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.onPrimary,
                          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 4),
                        ),
                        child: Icon(Icons.restaurant_menu, size: 64, color: Theme.of(context).colorScheme.primary),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'RESTAURANT',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary,
                              height: 1.1,
                            ),
                      ),
                      Text(
                        'OS',
                        style: Theme.of(context).textTheme.displayLarge?.copyWith(
                              color: Theme.of(context).colorScheme.secondary,
                              height: 1.1,
                            ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'The ultimate management and discovery platform for culinary excellence.',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
                            ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right side action block
          Expanded(
            flex: 1,
            child: Container(
              color: Theme.of(context).colorScheme.surface,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 64.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Select Workspace',
                        style: Theme.of(context).textTheme.displayMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your role to continue.',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 48),
                      _buildRoleButton(
                        context,
                        icon: Icons.person,
                        title: 'Customer App',
                        subtitle: 'Discover food & order',
                        color: Theme.of(context).colorScheme.primary,
                        onTap: () => context.go('/customer'),
                      ),
                      const SizedBox(height: 24),
                      _buildRoleButton(
                        context,
                        icon: Icons.storefront,
                        title: 'Restaurant Owner',
                        subtitle: 'Manage your business',
                        color: Theme.of(context).colorScheme.secondary,
                        onTap: () => context.go('/owner'),
                      ),
                      const SizedBox(height: 24),
                      _buildRoleButton(
                        context,
                        icon: Icons.admin_panel_settings,
                        title: 'Super Admin',
                        subtitle: 'Platform oversight',
                        color: Theme.of(context).colorScheme.onSurface,
                        onTap: () => context.go('/admin'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleButton(BuildContext context, {required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 3),
          boxShadow: const [
            BoxShadow(color: Colors.black12, offset: Offset(6, 6)),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                border: Border.all(color: color, width: 2),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(width: 24),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward, size: 24),
          ],
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
