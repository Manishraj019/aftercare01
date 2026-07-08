import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';
import 'package:restaurantos/core/widgets/tilted_card.dart';

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
    }
    context.go('/customer/menu');
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 800;

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
            onPressed: () => context.go('/'),
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.pureWhite),
            tooltip: 'Back',
          ),
          const Spacer(),
          // Profile Status (Login)
          IconButton(
            onPressed: () => context.go('/login'),
            icon: const Icon(Icons.account_circle_rounded, color: AppTheme.pureWhite, size: 28),
            tooltip: 'Profile / Login',
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
    return _HoverGlowCard(
      rotateAmplitude: 3.0,
      glowColor: const Color(0xFFFF4B55),
      onTap: () {}, // Action for Scan QR
      baseDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C1314), Color(0xFF0C090A)],
        ),
      ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            // Calculate a dynamic size for the scanner square based on available space
            // ensuring it always fits and never overflows
            final scannerSize = (availableHeight * 0.55).clamp(100.0, 300.0);
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // The Animated Scanner Box
                  SizedBox(
                    width: scannerSize,
                    height: scannerSize,
                    child: const _AnimatedScannerVisual(),
                  ),
                  const Spacer(),
                  // Clean typography
                  Text(
                    'Scan a QR Code',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.pureWhite,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Position within the frame',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white60,
                    ),
                  ),
                  const Spacer(),
                ],
              ),
            );
          },
        ),
    );
  }

  // ═══════════════════════════════════════════════
  // 2. ENTER TABLE BOX (Ultra sleek, glassmorphism blue/cyan)
  // ═══════════════════════════════════════════════
  Widget _buildTableCard(BuildContext context, WidgetRef ref) {
    return _HoverGlowCard(
      rotateAmplitude: 5.0,
      glowColor: const Color(0xFF38BDF8),
      onTap: () {}, // Inner interactions handled by text field/button
      baseDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)], // Sleek slate blue
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF38BDF8), // Bright cyan
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter your\nTable Number',
                    style: GoogleFonts.playfairDisplay(
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
                    style: GoogleFonts.inter(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: '#00',
                      hintStyle: GoogleFonts.inter(color: Colors.white24, fontSize: 32),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      contentPadding: const EdgeInsets.symmetric(vertical: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF334155))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF334155))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2)),
                    ),
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => _proceed(context, ref),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF38BDF8),
                        foregroundColor: const Color(0xFF0F172A),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text('JOIN', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
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
    return _HoverGlowCard(
      rotateAmplitude: 2.0, // Less rotation for big card
      glowColor: AppTheme.primaryGold,
      onTap: () => context.go('/customer/menu'),
      baseDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        color: AppTheme.bgDeepBurgundy,
        gradient: RadialGradient(
          center: const Alignment(0.5, 0.5),
          radius: 1.5,
          colors: [
            AppTheme.primaryGold.withValues(alpha: 0.15),
            AppTheme.bgDeepBurgundy,
          ],
        ),
      ),
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
            padding: const EdgeInsets.all(56.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'GOURMET\nCOLLECTION',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 56,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                    height: 1.0,
                    letterSpacing: 2,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Skip the wait and explore our full curated menu of culinary masterpieces crafted by our world-renowned chefs.',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    color: AppTheme.pureWhite.withValues(alpha: 0.8),
                    height: 1.6,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 48),
                InkWell(
                  onTap: () => context.go('/customer/menu'),
                  borderRadius: BorderRadius.circular(100),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.primaryGold, width: 2),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'BROWSE MENU',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryGold,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.arrow_forward_rounded, color: AppTheme.primaryGold, size: 20),
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
    )..repeat(reverse: true);
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

// ── Hover Glow Wrapper ──
class _HoverGlowCard extends StatefulWidget {
  final Widget child;
  final double rotateAmplitude;
  final Color glowColor;
  final BoxDecoration baseDecoration;
  final VoidCallback? onTap;

  const _HoverGlowCard({
    required this.child,
    this.rotateAmplitude = 3.0,
    required this.glowColor,
    required this.baseDecoration,
    this.onTap,
  });

  @override
  State<_HoverGlowCard> createState() => _HoverGlowCardState();
}

class _HoverGlowCardState extends State<_HoverGlowCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: TiltedCard(
          rotateAmplitude: widget.rotateAmplitude,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            width: double.infinity,
            decoration: widget.baseDecoration.copyWith(
              border: Border.all(
                color: _isHovered 
                    ? widget.glowColor.withValues(alpha: 0.9) 
                    : widget.glowColor.withValues(alpha: 0.2),
                width: _isHovered ? 2.0 : 1.5,
              ),
              boxShadow: [
                if (widget.baseDecoration.boxShadow != null)
                  ...widget.baseDecoration.boxShadow!,
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: _isHovered ? 0.3 : 0.0),
                  blurRadius: _isHovered ? 40 : 10,
                  spreadRadius: _isHovered ? 4 : -5,
                ),
              ],
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
