import 'package:flutter/material.dart';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/core/widgets/tilted_card.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

final selectedTableProvider = StateProvider<String?>((ref) => null);

class CustomerLandingScreen extends ConsumerStatefulWidget {
  const CustomerLandingScreen({super.key});

  @override
  ConsumerState<CustomerLandingScreen> createState() => _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends ConsumerState<CustomerLandingScreen>
    with SingleTickerProviderStateMixin {
  final _tableController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tableController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _proceed(BuildContext context, WidgetRef ref) {
    if (_tableController.text.trim().isNotEmpty) {
      ref.read(selectedTableProvider.notifier).state = _tableController.text.trim();
      context.go('/customer/menu');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a valid table number.', style: GoogleFonts.karla(color: Colors.white)),
          backgroundColor: AppTheme.primaryBurgundy,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 1024;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          color: Color(0xFF000000), // Pitch black background
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                const SizedBox(
                  height: 0,
                  width: 0,
                  child: Column(
                    children: [
                      Text('BistroOS Gateway', style: TextStyle(fontSize: 0, color: Colors.transparent)),
                      Text('Scan Table QR Code', style: TextStyle(fontSize: 0, color: Colors.transparent)),
                    ],
                  ),
                ),
                _buildHeader(context),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(isMobile ? 16.0 : 32.0),
                    child: isMobile ? _buildMobileStack(context, ref) : _buildDesktopGrid(context, ref),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header ──
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          // Back Button
          IconButton(
            onPressed: () => context.go('/landing'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.pureWhite),
            tooltip: 'Back',
          ),
          const Spacer(),
          // Profile Status (Login)
          Consumer(
            builder: (context, ref, child) {
              final authState = ref.watch(authViewModelProvider);
              final isLoggedIn = authState is Authenticated;
              return IconButton(
                onPressed: () {
                  if (isLoggedIn) {
                    context.push('/profile');
                  } else {
                    context.push('/login');
                  }
                },
                icon: const Icon(Icons.account_circle_rounded, color: AppTheme.pureWhite, size: 28),
                tooltip: 'Profile / Login',
              );
            },
          ),
        ],
      ),
    );
  }

  // ── Desktop Layout (Bento Grid) ──
  Widget _buildDesktopGrid(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        // Left Column (Scan QR + Enter Table)
        Expanded(
          flex: 4,
          child: Column(
            children: [
              Expanded(flex: 3, child: _buildScanCard()),
              const SizedBox(height: 24),
              Expanded(flex: 2, child: _buildTableCard(context, ref)),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column (Browse Menu)
        Expanded(
          flex: 5,
          child: _buildMenuCard(context),
        ),
      ],
    );
  }

  // ── Mobile Layout (Vertical Stack) ──
  Widget _buildMobileStack(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 400, child: _buildScanCard()),
          const SizedBox(height: 16),
          SizedBox(height: 350, child: _buildMenuCard(context)),
          const SizedBox(height: 16),
          SizedBox(height: 250, child: _buildTableCard(context, ref)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }



  // ═══════════════════════════════════════════════
  // 1. SCAN QR BOX (Dark red, responsive laser scanner)
  // ═══════════════════════════════════════════════
  Widget _buildScanCard() {
    return PremiumCard(
      primaryColor: const Color(0xFF818CF8),
      baseColor: const Color(0xFF131522),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Top Section
            Text(
              'Quick & Contactless'.toUpperCase(),
              style: GoogleFonts.karla(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF818CF8),
                letterSpacing: 1.5,
              ),
            ),
            const Spacer(),
            const SizedBox(
              height: 120, // Smaller animated scanner
              width: 120,
              child: _AnimatedScannerVisual(),
            ),
            const Spacer(),
            Text(
              'Scan to Order',
              style: GoogleFonts.playfairDisplaySc(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.1,
              ),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                key: const Key('simulateQrScanButton'),
                onPressed: () {
                  ref.read(selectedTableProvider.notifier).state = 'T-04';
                  context.go('/customer/menu');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF818CF8),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.qr_code_scanner_rounded, size: 20),
                    const SizedBox(width: 8),
                    Text('SCAN QR', style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 2. ENTER TABLE BOX (Ultra sleek, glassmorphism blue/cyan)
  // ═══════════════════════════════════════════════
  Widget _buildTableCard(BuildContext context, WidgetRef ref) {
    return PremiumCard(
      primaryColor: const Color(0xFF34D399),
      baseColor: const Color(0xFF0D1C16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Manual Entry'.toUpperCase(),
                    style: GoogleFonts.karla(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF34D399),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your\nTable Number',
                    style: GoogleFonts.playfairDisplaySc(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _tableController,
                    style: GoogleFonts.karla(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '#00',
                      hintStyle: GoogleFonts.karla(color: Colors.white24, fontSize: 32),
                      filled: true,
                      fillColor: const Color(0xFF06110B),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1B2C24))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF1B2C24))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF34D399), width: 2)),
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _proceed(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF34D399),
                        foregroundColor: const Color(0xFF06110B),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('JOIN', style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════
  // 3. BROWSE MENU BOX (Premium Gold/Burgundy, Photography styled)
  // ═══════════════════════════════════════════════
  Widget _buildMenuCard(BuildContext context) {
    return PremiumCard(
      primaryColor: AppTheme.primaryGold,
      baseColor: AppTheme.bgDeepBurgundy,
      child: Stack(
        children: [
          // Decorative giant background icon
          Positioned(
            right: -40,
            bottom: -40,
            child: Icon(
              Icons.restaurant_menu_rounded,
              size: 300,
              color: AppTheme.primaryGold.withValues(alpha: 0.05),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'GOURMET\nCOLLECTION',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    height: 1.1,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Skip the wait and explore our full curated menu of culinary masterpieces.',
                  style: GoogleFonts.karla(
                    fontSize: 14,
                    color: AppTheme.pureWhite.withValues(alpha: 0.8),
                    height: 1.4,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 24),
                InkWell(
                  onTap: () => context.go('/customer/menu'),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryGold, width: 1.5),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BROWSE MENU',
                          style: GoogleFonts.karla(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGold, size: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class PremiumCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color primaryColor;
  final Color baseColor;

  const PremiumCard({
    super.key,
    required this.child,
    this.onTap,
    required this.primaryColor,
    required this.baseColor,
  });

  @override
  State<PremiumCard> createState() => _PremiumCardState();
}

class _PremiumCardState extends State<PremiumCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeOutCubic,
          transform: _isHovered 
              ? (Matrix4.identity()..translate(0.0, -8.0)) 
              : Matrix4.identity(),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: widget.baseColor,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _isHovered ? widget.primaryColor.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.05),
              width: 1.5,
            ),
            boxShadow: [
              if (_isHovered)
                BoxShadow(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
            ],
            gradient: RadialGradient(
              center: Alignment.topLeft,
              radius: 2.0,
              colors: [
                _isHovered ? widget.primaryColor.withValues(alpha: 0.15) : widget.primaryColor.withValues(alpha: 0.05),
                widget.baseColor,
              ],
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

// ── Responsive Animated Scanner Visual ──
class _AnimatedScannerVisual extends StatefulWidget {
  const _AnimatedScannerVisual();

  @override
  State<_AnimatedScannerVisual> createState() => _AnimatedScannerVisualState();
}

class _AnimatedScannerVisualState extends State<_AnimatedScannerVisual> with SingleTickerProviderStateMixin {
  late AnimationController _scannerController;

  @override
  void initState() {
    super.initState();
    _scannerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _scannerController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxHeight;
        
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: const RadialGradient(
              center: Alignment.center,
              radius: 0.8,
              colors: [
                Color(0xFF3D1A1F), // Dark reddish core
                Color(0xFF14080A), // Fading to dark
              ],
            ),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Corner brackets
              Positioned(top: 0, left: 0, child: _buildCorner(0)),
              Positioned(top: 0, right: 0, child: _buildCorner(1)),
              Positioned(bottom: 0, right: 0, child: _buildCorner(2)),
              Positioned(bottom: 0, left: 0, child: _buildCorner(3)),
              
              // Animated scanner line
              AnimatedBuilder(
                animation: _scannerController,
                builder: (context, child) {
                  // The line moves from top padding to bottom padding
                  final verticalPadding = size * 0.15;
                  final travelDistance = size - (verticalPadding * 2) - 4; // 4 is line thickness
                  
                  return Positioned(
                    top: verticalPadding + (_scannerController.value * travelDistance),
                    left: size * 0.15,
                    right: size * 0.15,
                    child: Container(
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B55),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4B55).withValues(alpha: 0.8),
                            blurRadius: 12,
                            spreadRadius: 2,
                          ),
                          BoxShadow(
                            color: const Color(0xFFFF4B55).withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 6,
                          ),
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
    );
  }

  Widget _buildCorner(int quarterTurns) {
    return RotatedBox(
      quarterTurns: quarterTurns,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0xFFFF4B55), width: 4),
            left: BorderSide(color: Color(0xFFFF4B55), width: 4),
          ),
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16)),
        ),
      ),
    );
  }
}


