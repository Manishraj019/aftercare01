import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
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
  final _scrollController = ScrollController();
  bool _isScrolled = false;

  final List<String> _categories = [
    'All', 'Starters', 'Mains', 'Desserts', 'Beverages'
  ];

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final scrolled = _scrollController.offset > 10;
      if (scrolled != _isScrolled) {
        setState(() => _isScrolled = scrolled);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final menuState = ref.watch(menuViewModelProvider);
    final cartItems = ref.watch(cartViewModelProvider);
    final cartNotifier = ref.read(cartViewModelProvider.notifier);
    final selectedTable = ref.watch(selectedTableProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      body: Stack(
        children: [
          NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // ── Header ──────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                floating: false,
                expandedHeight: 0,
                toolbarHeight: 72,
                elevation: _isScrolled ? 8 : 0,
                shadowColor: Colors.black,
                backgroundColor: _isScrolled ? AppTheme.bgDeepBurgundy.withValues(alpha: 0.95) : AppTheme.bgDeepBurgundy,
                surfaceTintColor: Colors.transparent,
                title: Row(
                  children: [
                    // Elegant Logo Element
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                        gradient: RadialGradient(
                          colors: [AppTheme.primaryGold.withValues(alpha: 0.2), Colors.transparent],
                        )
                      ),
                      child: const Icon(Icons.restaurant, color: AppTheme.primaryGold, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gourmet Bistro',
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.primaryGold, fontSize: 22,
                            fontWeight: FontWeight.bold, letterSpacing: 1.2,
                          ),
                        ),
                        if (selectedTable != null)
                          Text(
                            'Table $selectedTable',
                            style: GoogleFonts.inter(
                              color: AppTheme.textMuted, fontSize: 12, letterSpacing: 0.5,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                actions: [
                  GestureDetector(
                    onTap: () => context.push('/customer/cart'),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 20),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppTheme.bgDarkCharcoal.withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                              border: Border.all(color: AppTheme.borderLight),
                            ),
                            child: const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryGold, size: 22),
                          ),
                          if (cartNotifier.itemCount > 0)
                            Positioned(
                              right: -2, top: 2,
                              child: Container(
                                padding: const EdgeInsets.all(5),
                                decoration: const BoxDecoration(
                                  color: AppTheme.primaryGold,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${cartNotifier.itemCount}',
                                  style: GoogleFonts.inter(
                                    color: AppTheme.bgDarkCharcoal, fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // ── Search & Filter ───────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.bgDarkCharcoal,
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
                          style: GoogleFonts.inter(color: AppTheme.pureWhite),
                          decoration: InputDecoration(
                            hintText: 'Search the menu...',
                            hintStyle: GoogleFonts.inter(color: AppTheme.textMuted),
                            prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primaryGold, size: 22),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            filled: true,
                            fillColor: AppTheme.bgDarkPanel,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.borderLight),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: BorderSide(color: AppTheme.borderLight),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(30),
                              borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _onlyVeg = !_onlyVeg),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _onlyVeg ? AppTheme.vegGreen.withValues(alpha: 0.15) : AppTheme.bgDarkPanel,
                            border: Border.all(
                              color: _onlyVeg ? AppTheme.vegGreen : AppTheme.borderLight,
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              VegNonVegIcon(isVeg: true, size: 14),
                              const SizedBox(width: 8),
                              Text('Veg', style: GoogleFonts.inter(
                                color: _onlyVeg ? AppTheme.vegGreen : AppTheme.textMuted,
                                fontWeight: _onlyVeg ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Category Pills ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Container(
                  color: AppTheme.bgDarkCharcoal,
                  height: 60,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppTheme.primaryBurgundy : AppTheme.bgDarkPanel,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryGold : AppTheme.borderLight,
                                width: isSelected ? 1.5 : 1,
                              ),
                              boxShadow: isSelected ? [
                                BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.2), blurRadius: 10, spreadRadius: 1)
                              ] : [],
                            ),
                            child: Text(
                              cat,
                              style: GoogleFonts.inter(
                                color: isSelected ? AppTheme.primaryGold : AppTheme.textMuted,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                fontSize: 14, letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              
              // Spacing
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],

            // ── Menu List ─────────────────────────────────────────────
            body: menuState.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppTheme.primaryGold),
              ),
              error: (err, _) => Center(
                child: Text('ERROR: $err', style: GoogleFonts.inter(color: AppTheme.textLight)),
              ),
              data: (items) {
                final filteredItems = items.where((item) {
                  final matchesCategory =
                      _selectedCategory == 'All' || item.category == _selectedCategory;
                  final matchesVeg = !_onlyVeg || item.isVegetarian;
                  final matchesSearch =
                      item.name.toLowerCase().contains(_searchQuery) ||
                          item.description.toLowerCase().contains(_searchQuery);
                  return matchesCategory && matchesVeg && matchesSearch;
                }).toList();

                if (filteredItems.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off_rounded, size: 64, color: AppTheme.textMuted),
                        const SizedBox(height: 16),
                        Text('No dishes found',
                            style: GoogleFonts.playfairDisplay(color: AppTheme.primaryGold, fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final crossAxisCount = constraints.maxWidth > 900 ? 3 : constraints.maxWidth > 600 ? 2 : 1;
                    return GridView.builder(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, cartNotifier.itemCount > 0 ? 120 : 40),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        childAspectRatio: 0.85,
                        crossAxisSpacing: 24,
                        mainAxisSpacing: 24,
                      ),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final cartIdx = cartItems.indexWhere((e) => e.itemId == item.id);
                        final quantityInCart = cartIdx >= 0 ? cartItems[cartIdx].quantity : 0;
                        final isTrending = index < 3;

                        return _LuxuryMenuCard(
                          item: item,
                          quantityInCart: quantityInCart,
                          isTrending: isTrending,
                          onTap: () => _showLuxuryDetailSidePanel(context, item, cartNotifier, cartItems),
                          onAdd: () => cartNotifier.addItem(item),
                          onIncrement: () => cartNotifier.updateQuantity(item.id, 1),
                          onDecrement: () => cartNotifier.updateQuantity(item.id, -1),
                        );
                      },
                    );
                  }
                );
              },
            ),
          ),

          // ── Sticky Bottom Cart Bar ──────────────────────────────
          if (cartNotifier.itemCount > 0)
            Positioned(
              left: 20, right: 20, bottom: 24,
              child: GestureDetector(
                onTap: () => context.push('/customer/cart'),
                child: GlassContainer(
                  blur: 20,
                  opacity: 0.8,
                  color: AppTheme.bgDeepBurgundy.withValues(alpha: 0.85),
                  border: Border.all(color: AppTheme.primaryGold.withValues(alpha: 0.5), width: 1.5),
                  borderRadius: BorderRadius.circular(16),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cartNotifier.itemCount} ITEM${cartNotifier.itemCount > 1 ? 'S' : ''}',
                            style: GoogleFonts.inter(color: AppTheme.primaryGold, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          Text(
                            '\$${cartNotifier.subtotal.toStringAsFixed(2)}',
                            style: GoogleFonts.playfairDisplay(color: AppTheme.pureWhite, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          Text(
                            'View Cart',
                            style: GoogleFonts.inter(color: AppTheme.pureWhite, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(color: AppTheme.primaryGold, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.arrow_forward_ios_rounded, color: AppTheme.bgDeepBurgundy, size: 16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showLuxuryDetailSidePanel(BuildContext context, dynamic item,
      CartViewModel cartNotifier, List<dynamic> cartItems) {
    
    // Instead of bottom sheet, we use a custom dialog that slides from the right
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withValues(alpha: 0.6), // Dim background
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Material(
            color: Colors.transparent,
            child: SizedBox(
              width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.9,
              height: double.infinity,
              child: _LuxuryDetailPanelContent(
                item: item,
                cartNotifier: cartNotifier,
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutQuart)),
          child: child,
        );
      },
    );
  }
}

// ─── Luxury Detail Panel Content ────────────────────────────────────
class _LuxuryDetailPanelContent extends ConsumerStatefulWidget {
  final dynamic item;
  final CartViewModel cartNotifier;

  const _LuxuryDetailPanelContent({required this.item, required this.cartNotifier});

  @override
  ConsumerState<_LuxuryDetailPanelContent> createState() => _LuxuryDetailPanelContentState();
}

class _LuxuryDetailPanelContentState extends ConsumerState<_LuxuryDetailPanelContent> {
  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartViewModelProvider);
    final cartIdx = cartItems.indexWhere((e) => e.itemId == widget.item.id);
    final currentQty = cartIdx >= 0 ? cartItems[cartIdx].quantity : 0;
    final hasInCart = currentQty > 0;

    return GlassContainer(
      blur: 30,
      opacity: 0.85,
      borderRadius: const BorderRadius.horizontal(left: Radius.circular(32)),
      border: Border(
        left: BorderSide(color: AppTheme.borderLight, width: 1),
        top: BorderSide(color: AppTheme.borderLight, width: 1),
        bottom: BorderSide(color: AppTheme.borderLight, width: 1),
      ),
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Hero Image with Fade Mask
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(32)),
                      child: Image.network(
                        widget.item.imageUrl,
                        height: 350, width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stack) => Container(
                          height: 350,
                          color: AppTheme.bgDarkPanel,
                          child: const Icon(Icons.restaurant, size: 80, color: AppTheme.textMuted),
                        ),
                      ),
                    ),
                    // Gradient overlay for smooth transition to content
                    Positioned(
                      bottom: 0, left: 0, right: 0,
                      height: 150,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [AppTheme.bgDarkPanel.withValues(alpha: 0.95), Colors.transparent],
                          ),
                        ),
                      ),
                    ),
                    // Close button
                    Positioned(
                      top: 24, right: 24,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: GlassContainer(
                          blur: 10, opacity: 0.3,
                          borderRadius: BorderRadius.circular(30),
                          padding: const EdgeInsets.all(12),
                          child: const Icon(Icons.close, color: AppTheme.pureWhite, size: 24),
                        ),
                      ),
                    ),
                  ],
                ),

                // Details
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Chef's Tags Row
                      Row(
                        children: [
                          VegNonVegIcon(isVeg: widget.item.isVegetarian),
                          const SizedBox(width: 12),
                          if (widget.item.isBestSeller == true)
                            _buildChefTag(Icons.star, 'Popular', AppTheme.primaryGold),
                          const SizedBox(width: 8),
                          if (widget.item.name.toLowerCase().contains('spicy') || widget.item.description.toLowerCase().contains('spicy'))
                            _buildChefTag(Icons.local_fire_department, 'Spicy', AppTheme.nonVegRed),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text(widget.item.name,
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.pureWhite, fontSize: 36,
                            fontWeight: FontWeight.bold, height: 1.1,
                          )),
                      const SizedBox(height: 16),
                      Text(
                        '\$${widget.item.price.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(
                          fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.primaryGold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      Text('About this dish',
                          style: GoogleFonts.playfairDisplay(
                            color: AppTheme.pureWhite, fontSize: 20,
                            fontWeight: FontWeight.w600, fontStyle: FontStyle.italic
                          )),
                      const SizedBox(height: 16),
                      Text(widget.item.description,
                          style: GoogleFonts.inter(
                            color: AppTheme.textLight, fontSize: 16, height: 1.8,
                          )),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Action Bar
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: GlassContainer(
              blur: 20, opacity: 0.9,
              borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(32)),
              border: Border(top: BorderSide(color: AppTheme.borderLight)),
              padding: const EdgeInsets.all(32),
              child: hasInCart
                ? Center(
                    child: AddStepperButton(
                      quantity: currentQty,
                      onAdd: () => widget.cartNotifier.updateQuantity(widget.item.id, 1),
                      onRemove: () => widget.cartNotifier.updateQuantity(widget.item.id, -1),
                    ),
                  )
                : SizedBox(
                    width: double.infinity,
                    child: FoodPrimaryButton(
                      label: 'ADD TO CART',
                      icon: Icons.add_shopping_cart,
                      onPressed: () => widget.cartNotifier.addItem(widget.item),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChefTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        border: Border.all(color: color.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// ─── Luxury Menu Card ─────────────────────────────────────────────────
class _LuxuryMenuCard extends StatefulWidget {
  final dynamic item;
  final int quantityInCart;
  final bool isTrending;
  final VoidCallback onTap;
  final VoidCallback onAdd;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _LuxuryMenuCard({
    required this.item,
    required this.quantityInCart,
    required this.isTrending,
    required this.onTap,
    required this.onAdd,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  State<_LuxuryMenuCard> createState() => _LuxuryMenuCardState();
}

class _LuxuryMenuCardState extends State<_LuxuryMenuCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          transform: Matrix4.identity()..translate(0.0, _isHovered ? -8.0 : 0.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: _isHovered ? [
              BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 10))
            ] : [
              BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 4))
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background Image
                Image.network(
                  widget.item.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stack) => Container(
                    color: AppTheme.bgDarkPanel,
                    child: const Icon(Icons.restaurant, size: 48, color: AppTheme.textMuted),
                  ),
                ),
                
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.black.withValues(alpha: 0.4),
                        AppTheme.bgDarkCharcoal.withValues(alpha: 0.95),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          VegNonVegIcon(isVeg: widget.item.isVegetarian),
                          if (widget.isTrending)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.bgDeepBurgundy.withValues(alpha: 0.8),
                                border: Border.all(color: AppTheme.primaryGold),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: AppTheme.primaryGold, size: 12),
                                  const SizedBox(width: 4),
                                  Text('Bestseller', style: GoogleFonts.inter(color: AppTheme.primaryGold, fontSize: 10, fontWeight: FontWeight.bold)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        widget.item.name,
                        style: GoogleFonts.playfairDisplay(
                          color: AppTheme.pureWhite,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          height: 1.2,
                        ),
                        maxLines: 2, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '\$${widget.item.price.toStringAsFixed(2)}',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryGold,
                              fontSize: 18, fontWeight: FontWeight.bold,
                            ),
                          ),
                          AddStepperButton(
                            quantity: widget.quantityInCart,
                            onAdd: () {
                              if (widget.quantityInCart == 0) {
                                widget.onAdd();
                              } else {
                                widget.onIncrement();
                              }
                            },
                            onRemove: widget.onDecrement,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
