import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

class HomeDiscoveryScreen extends StatefulWidget {
  const HomeDiscoveryScreen({super.key});

  @override
  State<HomeDiscoveryScreen> createState() => _HomeDiscoveryScreenState();
}

class _HomeDiscoveryScreenState extends State<HomeDiscoveryScreen> {
  final List<Map<String, dynamic>> _categories = [
    {'image': 'https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?q=80&w=200&auto=format&fit=crop', 'name': 'Pizza'},
    {'image': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=200&auto=format&fit=crop', 'name': 'Burger'},
    {'image': 'https://images.unsplash.com/photo-1563379091339-03b21ab4a4f8?q=80&w=200&auto=format&fit=crop', 'name': 'Biryani'},
    {'image': 'https://images.unsplash.com/photo-1554118811-1e0d58224f24?q=80&w=200&auto=format&fit=crop', 'name': 'Coffee'},
    {'image': 'https://images.unsplash.com/photo-1512621776951-a57141f2eefd?q=80&w=200&auto=format&fit=crop', 'name': 'Healthy'},
  ];

  final List<Map<String, dynamic>> _banners = [
    {
      'title': 'Flat 50% OFF',
      'subtitle': 'on your first order',
      'code': 'WELCOME50',
      'color': const Color(0xFFE53935), // Vibrant Red
      'image': 'https://images.unsplash.com/photo-1504674900247-0877df9cc836?q=80&w=400&auto=format&fit=crop',
    },
    {
      'title': 'Free Delivery',
      'subtitle': 'on orders above ₹199',
      'code': 'FREEDEL',
      'color': const Color(0xFF1E88E5), // Vibrant Blue
      'image': 'https://images.unsplash.com/photo-1555939594-58d7cb561ad1?q=80&w=400&auto=format&fit=crop',
    }
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal, // Actually light in inverted theme
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSearchBar(),
            const SizedBox(height: 24),
            _buildCategoriesSection(),
            const SizedBox(height: 24),
            _buildBannerCarousel(),
            const SizedBox(height: 32),
            _buildTrendingReelsSection(),
            const SizedBox(height: 32),
            _buildTopRestaurantsSection(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.bgDarkCharcoal,
      elevation: 0,
      title: Row(
        children: [
          const Icon(Icons.location_on, color: AppTheme.primaryGold, size: 28),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Home',
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.pureWhite, // PureWhite acts as dark text
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: AppTheme.pureWhite, size: 18),
                  ],
                ),
                Text(
                  '123 Main Street, Sector 4...',
                  style: GoogleFonts.karla(
                    fontSize: 12,
                    color: AppTheme.textMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        _buildCartAction(),
        _buildProfileMenu(),
      ],
    );
  }

  Widget _buildCartAction() {
    return Consumer(
      builder: (context, ref, child) {
        final cartNotifier = ref.watch(cartViewModelProvider.notifier);
        final count = cartNotifier.itemCount;
        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.pureWhite),
              onPressed: () => context.push('/customer/cart'),
            ),
            if (count > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppTheme.nonVegRed,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildProfileMenu() {
    return Consumer(
      builder: (context, ref, child) {
        final authState = ref.watch(authViewModelProvider);
        if (authState is Authenticated) {
          return PopupMenuButton<String>(
            icon: const Icon(Icons.person_outline, color: AppTheme.pureWhite),
            color: AppTheme.bgDarkPanel,
            offset: const Offset(0, 48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            onSelected: (value) {
              if (value == 'liked_reels') {
                context.push('/profile');
              } else if (value == 'orders') {
                context.push('/customer/orders');
              } else if (value == 'sign_out') {
                ref.read(authViewModelProvider.notifier).logout();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'liked_reels',
                child: Row(
                  children: [
                    const Icon(Icons.favorite_border, color: AppTheme.pureWhite, size: 20),
                    const SizedBox(width: 12),
                    Text('Liked Reels', style: TextStyle(color: AppTheme.pureWhite)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'orders',
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long, color: AppTheme.pureWhite, size: 20),
                    const SizedBox(width: 12),
                    Text('Orders', style: TextStyle(color: AppTheme.pureWhite)),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'sign_out',
                child: Row(
                  children: [
                    const Icon(Icons.logout, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          );
        }
        return IconButton(
          icon: const Icon(Icons.person_outline, color: AppTheme.pureWhite),
          onPressed: () => context.push('/login'),
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppTheme.bgDarkPanel,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search for 'Biryani'",
                  hintStyle: TextStyle(color: AppTheme.textMuted.withOpacity(0.6), fontSize: 14),
                  prefixIcon: const Icon(Icons.search, color: AppTheme.primaryGold),
                  suffixIcon: const Icon(Icons.mic_none, color: AppTheme.primaryGold),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 16),
                ),
                style: const TextStyle(color: AppTheme.pureWhite),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            height: 52,
            width: 52,
            decoration: BoxDecoration(
              color: AppTheme.bgDarkPanel,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.qr_code_scanner, color: AppTheme.primaryGold),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  backgroundColor: AppTheme.bgDarkPanel,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Scan QR Code', style: GoogleFonts.playfairDisplaySc(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        ListTile(
                          leading: const Icon(Icons.photo_library, color: AppTheme.primaryGold),
                          title: Text('Choose QR from files or images', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/restaurant/1');
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.camera_alt, color: AppTheme.primaryGold),
                          title: Text('Camera', style: GoogleFonts.karla(color: AppTheme.pureWhite)),
                          onTap: () {
                            Navigator.pop(context);
                            context.go('/restaurant/1');
                          },
                        ),
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

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'What\'s on your mind?',
            style: GoogleFonts.playfairDisplaySc(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.pureWhite,
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        image: DecorationImage(
                          image: NetworkImage(cat['image']),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      cat['name'],
                      style: GoogleFonts.karla(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.pureWhite,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBannerCarousel() {
    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _banners.length,
        itemBuilder: (context, index) {
          final banner = _banners[index];
          return Container(
            width: 300,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: banner['color'],
              image: DecorationImage(
                image: NetworkImage(banner['image']),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.4),
                  BlendMode.darken,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    banner['title'],
                    style: GoogleFonts.poppins(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    banner['subtitle'],
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Code: ${banner['code']}',
                      style: GoogleFonts.karla(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: banner['color'],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrendingReelsSection() {
    return Container(
      color: Colors.black, // Dark cinematic background for Reels section
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Trending Reels',
                      style: GoogleFonts.playfairDisplaySc(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/reels'),
                  child: Text(
                    'See All',
                    style: GoogleFonts.karla(color: AppTheme.primaryGold, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: 5,
              itemBuilder: (context, index) {
                return _buildReelPreviewCard(index);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReelPreviewCard(int index) {
    return GestureDetector(
      onTap: () => context.go('/reels'),
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          image: const DecorationImage(
            image: NetworkImage('https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=400&auto=format&fit=crop'),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black.withOpacity(0.3),
                Colors.black.withOpacity(0.9),
              ],
              stops: const [0.4, 0.7, 1.0],
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 16),
              ),
              Row(
                children: [
                  const Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Cheese Pull 🤤',
                      style: GoogleFonts.karla(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopRestaurantsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Top Restaurants near you',
            style: GoogleFonts.playfairDisplaySc(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.pureWhite,
            ),
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 4,
          itemBuilder: (context, index) {
            return _buildRestaurantCard(index);
          },
        ),
      ],
    );
  }

  Widget _buildRestaurantCard(int index) {
    return GestureDetector(
      onTap: () => context.go('/restaurant/1'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          color: Colors.transparent, // Swiggy style is often transparent bg with large image
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image with Offer overlay
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=800&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                        stops: const [0.5, 1.0],
                      ),
                    ),
                  ),
                ),
                // Favorite Button
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.favorite_border, color: Colors.red, size: 20),
                  ),
                ),
                // Promoted badge
                if (index == 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'PROMOTED',
                        style: GoogleFonts.karla(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                // Offer Text at bottom of image
                Positioned(
                  bottom: 16,
                  left: 16,
                  child: Text(
                    '₹125 OFF ABOVE ₹249',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Details
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gourmet Bistro',
                          style: GoogleFonts.karla(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.pureWhite,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Italian, Pizza, Pasta',
                          style: GoogleFonts.karla(
                            fontSize: 14,
                            color: AppTheme.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32), // Green rating
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '4.8',
                              style: GoogleFonts.karla(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.star, color: Colors.white, size: 12),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '30-35 mins',
                        style: GoogleFonts.karla(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.pureWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

