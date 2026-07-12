import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:restaurantos/features/menu/presentation/viewmodels/cart_viewmodel.dart';
import 'package:restaurantos/features/menu/domain/entities/menu_item_entity.dart';

class RestaurantProfileScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const RestaurantProfileScreen({super.key, required this.restaurantId});

  @override
  ConsumerState<RestaurantProfileScreen> createState() => _RestaurantProfileScreenState();
}

class _RestaurantProfileScreenState extends ConsumerState<RestaurantProfileScreen> {
  final ScrollController _scrollController = ScrollController();
  double _scrollOffset = 0.0;
  bool _isFavorite = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() {
        _scrollOffset = _scrollController.offset;
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const darkBg = Color(0xFF141414);
    const darkText = Color(0xFFFFFFFF);

    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: _buildFloatingCart(context),
      body: SingleChildScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(top: 60, bottom: 100, left: 24, right: 24),
                  decoration: const BoxDecoration(
                    color: darkBg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: darkText),
                            onPressed: () {
                              if (context.canPop()) {
                                context.pop();
                              } else {
                                context.go('/customer');
                              }
                            },
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(_isFavorite ? Icons.favorite : Icons.favorite_border, color: _isFavorite ? Colors.red : darkText),
                                onPressed: () {
                                  setState(() {
                                    _isFavorite = !_isFavorite;
                                  });
                                  if (_isFavorite) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Added to favorites!'), behavior: SnackBarBehavior.floating),
                                    );
                                  }
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.share, color: darkText),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      backgroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      title: Text('Share Restaurant', style: GoogleFonts.playfairDisplaySc(fontWeight: FontWeight.bold, color: Colors.black)),
                                      content: Text('Share this restaurant with your friends!', style: GoogleFonts.karla(color: Colors.black87)),
                                      actions: [
                                        TextButton(
                                          onPressed: () => Navigator.pop(context),
                                          child: Text('Close', style: GoogleFonts.karla(color: AppTheme.primaryGold, fontWeight: FontWeight.bold)),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          )
                        ],
                      ),
                      const SizedBox(height: 32),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hush Modern\nRestaurant',
                                  style: GoogleFonts.playfairDisplaySc(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                    color: darkText,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Experience the true taste of culinary excellence in a modern setting.',
                                  style: GoogleFonts.karla(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Checking table availability...'), behavior: SnackBarBehavior.floating),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppTheme.primaryGold,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  child: Text(
                                    'Reservation',
                                    style: GoogleFonts.karla(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Transform.translate(
                              // Parallax effect: image moves up slightly as you scroll down
                              offset: Offset(30, -20 + (_scrollOffset * 0.4)),
                              child: Transform.rotate(
                                angle: 0.1,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Image.network(
                                    'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=800&auto=format&fit=crop',
                                    height: 200,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 60,
                  left: 0,
                  right: 0,
                  child: Container(
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(40),
                        topRight: Radius.circular(40),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -40,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: const [
                      HoverActionCard(title: 'Menu', icon: Icons.menu_book, route: '/customer/menu'),
                      HoverActionCard(title: 'Reels', icon: Icons.play_circle_fill, route: '/reels'),
                      HoverActionCard(title: 'Dine In', icon: Icons.table_restaurant),
                      HoverActionCard(title: 'Offers', icon: Icons.local_offer),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 80),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  Text(
                    'Our Menu Highlights',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: darkBg,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMenuHighlightCard('Salmon Sushi', 'Fresh norwegian salmon', '\$12.99', 'https://images.unsplash.com/photo-1579871494447-9811cf80d66c?q=80&w=300&auto=format&fit=crop'),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildMenuHighlightCard('Tuna Roll', 'Spicy tuna with mayo', '\$14.99', 'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=300&auto=format&fit=crop'),
                      ),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 48),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              color: darkBg,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Make to Order\nyour Sushi',
                          style: GoogleFonts.playfairDisplaySc(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: darkText,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'We prepare everything fresh exactly the way you want it.',
                          style: GoogleFonts.karla(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            context.push('/customer/menu');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryGold,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Order Now', style: GoogleFonts.karla(fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(100),
                    child: Image.network(
                      'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=300&auto=format&fit=crop',
                      width: 120,
                      height: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
              child: Column(
                children: [
                  Text(
                    'Contact & Details',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: darkBg,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        )
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?q=80&w=300&auto=format&fit=crop',
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('123 Culinary Avenue, NY', style: GoogleFonts.karla(fontWeight: FontWeight.w600, color: darkBg)),
                              const SizedBox(height: 4),
                              Text('Open: 10:00 AM - 11:00 PM', style: GoogleFonts.karla(color: Colors.grey)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 16),
                                  Text(' 4.8 (2k+ Reviews)', style: GoogleFonts.karla(fontSize: 12, fontWeight: FontWeight.bold, color: darkBg)),
                                ],
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuHighlightCard(String title, String desc, String price, String img) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Image.network(
              img,
              height: 100,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87)),
                const SizedBox(height: 4),
                Text(desc, style: GoogleFonts.karla(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(price, style: GoogleFonts.karla(fontWeight: FontWeight.bold, color: AppTheme.primaryGold)),
                    AnimatedAddButton(
                      onAdd: () {
                        final priceVal = double.tryParse(price.replaceAll('\$', '')) ?? 0.0;
                        ref.read(cartViewModelProvider.notifier).addItem(
                          MenuItemEntity(
                            id: 'highlight_$title',
                            restaurantId: widget.restaurantId,
                            name: title,
                            description: desc,
                            price: priceVal,
                            category: 'Highlights',
                            imageUrl: img,
                            isVegetarian: false,
                          )
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('$title added to cart!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildFloatingCart(BuildContext context) {
    final cartNotifier = ref.watch(cartViewModelProvider.notifier);
    final count = cartNotifier.itemCount;
    if (count == 0) return const SizedBox.shrink();

    return FloatingActionButton.extended(
      onPressed: () => context.push('/customer/cart'),
      backgroundColor: AppTheme.primaryGold,
      icon: const Icon(Icons.shopping_cart, color: Colors.white),
      label: Text(
        'Cart ($count)',
        style: GoogleFonts.karla(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class HoverActionCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String? route;

  const HoverActionCard({super.key, required this.title, required this.icon, this.route});

  @override
  State<HoverActionCard> createState() => _HoverActionCardState();
}

class _HoverActionCardState extends State<HoverActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            if (widget.route != null) {
              context.go(widget.route!);
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${widget.title} coming soon!'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            height: 90,
            transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
            decoration: BoxDecoration(
              color: _isHovered ? AppTheme.primaryGold : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _isHovered ? AppTheme.primaryGold.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.1),
                  blurRadius: _isHovered ? 20 : 15,
                  offset: Offset(0, _isHovered ? 12 : 8),
                )
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: _isHovered ? 1.1 : 1.0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(widget.icon, color: _isHovered ? Colors.white : AppTheme.primaryGold, size: 28),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.title,
                  style: GoogleFonts.karla(
                    color: _isHovered ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AnimatedAddButton extends StatefulWidget {
  final VoidCallback onAdd;
  const AnimatedAddButton({super.key, required this.onAdd});

  @override
  State<AnimatedAddButton> createState() => _AnimatedAddButtonState();
}

class _AnimatedAddButtonState extends State<AnimatedAddButton> {
  bool _isAdded = false;

  void _handleTap() {
    if (_isAdded) return;
    widget.onAdd();
    setState(() => _isAdded = true);
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _isAdded = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (child, animation) => ScaleTransition(scale: animation, child: child),
        child: _isAdded
            ? const Icon(Icons.check_circle, color: Colors.green, size: 28, key: ValueKey('check'))
            : const Icon(Icons.add_circle, color: AppTheme.primaryGold, size: 28, key: ValueKey('add')),
      ),
    );
  }
}
