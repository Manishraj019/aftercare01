import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

class ReelsFeedScreen extends ConsumerStatefulWidget {
  const ReelsFeedScreen({super.key});

  @override
  ConsumerState<ReelsFeedScreen> createState() => _ReelsFeedScreenState();
}

class _ReelsFeedScreenState extends ConsumerState<ReelsFeedScreen> {
  final PageController _pageController = PageController();

  final List<Map<String, dynamic>> _reels = [
    {
      'videoUrl': 'https://images.unsplash.com/photo-1513104890138-7c749659a591?q=80&w=800&auto=format&fit=crop', // Placeholder for video
      'restaurantName': 'Gourmet Bistro',
      'restaurantId': '1',
      'itemName': 'Woodfired Margherita',
      'description': 'The ultimate cheese pull! 🤤🍕',
      'price': '₹499',
      'likes': '12.4K',
      'comments': '243',
      'rating': '4.8',
      'distance': '1.2 km',
    },
    {
      'videoUrl': 'https://images.unsplash.com/photo-1568901346375-23c9450c58cd?q=80&w=800&auto=format&fit=crop', 
      'restaurantName': 'Burger Bliss',
      'restaurantId': '2',
      'itemName': 'Double Truffle Burger',
      'description': 'Juicy, messy, and absolutely perfect. 🍔✨',
      'price': '₹349',
      'likes': '8.2K',
      'comments': '156',
      'rating': '4.6',
      'distance': '2.5 km',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Reels',
          style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final count = ref.watch(cartViewModelProvider.notifier).itemCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                    onPressed: () => context.push('/customer/cart'),
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppTheme.nonVegRed,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: AppTheme.pureWhite, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PageView.builder(
        controller: _pageController,
        scrollDirection: Axis.vertical,
        itemCount: _reels.length,
        itemBuilder: (context, index) {
          return _buildReelItem(_reels[index]);
        },
      ),
    );
  }

  Widget _buildReelItem(Map<String, dynamic> reel) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background Video/Image
        Image.network(
          reel['videoUrl'],
          fit: BoxFit.cover,
        ),
        
        // Gradient Overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.3),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.8),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
        
        // Right Side Actions
        Positioned(
          right: 16,
          bottom: 120,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () {
                  final authState = ref.read(authViewModelProvider);
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to like reels!'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Liked ${reel['itemName']}!'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: _buildActionIcon(Icons.favorite, reel['likes'], Colors.red),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  final authState = ref.read(authViewModelProvider);
                  if (authState is! Authenticated) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please log in to review reels!'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Opening reviews for ${reel['itemName']}...'), behavior: SnackBarBehavior.floating),
                  );
                },
                child: _buildActionIcon(Icons.comment_rounded, 'Review', Colors.white),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/restaurant/${reel['restaurantId']}'),
                child: _buildActionIcon(Icons.storefront_rounded, 'Visit', Colors.white),
              ),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/restaurant/${reel['restaurantId']}'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1552566626-52f8b828add9?q=80&w=100&auto=format&fit=crop'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Bottom Info & Order Now
        Positioned(
          left: 16,
          right: 80,
          bottom: 40,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () => context.go('/restaurant/${reel['restaurantId']}'),
                child: Row(
                  children: [
                    Text(
                      reel['restaurantName'],
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.check_circle, color: Colors.blue, size: 16),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Text(
                reel['description'],
                style: GoogleFonts.karla(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const SizedBox(height: 16),
              // Interactive Order Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryGold.withValues(alpha: 0.1),
                      blurRadius: 10,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            reel['itemName'],
                            style: GoogleFonts.karla(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 15,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reel['price'],
                            style: GoogleFonts.karla(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryGold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        final priceString = reel['price'] as String;
                        final priceVal = double.tryParse(priceString.replaceAll('₹', '').replaceAll('\$', '')) ?? 0.0;
                        ref.read(cartViewModelProvider.notifier).addItem(
                          MenuItemEntity(
                            id: 'reel_item_${reel['itemName']}',
                            restaurantId: reel['restaurantId'] ?? '1',
                            name: reel['itemName'],
                            description: reel['description'],
                            price: priceVal,
                            category: 'Reels',
                            imageUrl: reel['videoUrl'],
                            isVegetarian: true,
                          )
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${reel['itemName']} added to cart!'),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: AppTheme.primaryBurgundy,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: Text(
                        'Add to Cart',
                        style: GoogleFonts.karla(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionIcon(IconData icon, String label, Color iconColor) {
    return Column(
      children: [
        Icon(icon, color: iconColor, size: 36),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.karla(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
