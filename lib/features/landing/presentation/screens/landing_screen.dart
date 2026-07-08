import 'dart:math';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/tilted_card.dart';

class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _shimmerController;
  late Animation<double> _fadeAnim;
  late Animation<double> _titleSlide;
  late Animation<double> _subtitleFade;
  late Animation<double> _cardsFade;

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
    );
    _titleSlide = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.15, 0.55, curve: Curves.easeOutCubic),
    );
    _subtitleFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.35, 0.7, curve: Curves.easeOut),
    );
    _cardsFade = CurvedAnimation(
      parent: _fadeController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;
    final isTablet = screenWidth >= 700 && screenWidth < 1100;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A0A0A),
              Color(0xFF1A0A10),
              Color(0xFF0C0C0C),
              Color(0xFF0A0F1A),
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Ambient Gold Orbs ──
            Positioned(
              top: -120,
              right: -80,
              child: _buildAmbientOrb(280, AppTheme.primaryGold.withValues(alpha: 0.04)),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _buildAmbientOrb(220, AppTheme.primaryBurgundy.withValues(alpha: 0.06)),
            ),
            Positioned(
              top: MediaQuery.of(context).size.height * 0.4,
              left: MediaQuery.of(context).size.width * 0.5 - 150,
              child: _buildAmbientOrb(300, AppTheme.primaryGold.withValues(alpha: 0.02)),
            ),

            // ── Main Content ──
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 20 : (isTablet ? 40 : 80),
                    vertical: isMobile ? 32 : 48,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // ── Logo + Brand ──
                      FadeTransition(
                        opacity: _fadeAnim,
                        child: _buildLogo(),
                      ),
                      const SizedBox(height: 24),

                      // ── Title ──
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.3),
                          end: Offset.zero,
                        ).animate(_titleSlide),
                        child: FadeTransition(
                          opacity: _titleSlide,
                          child: _buildTitle(isMobile),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // ── Tagline ──
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: _buildTagline(isMobile),
                      ),
                      SizedBox(height: isMobile ? 40 : 56),

                      // ── Divider with shimmer ──
                      FadeTransition(
                        opacity: _subtitleFade,
                        child: _buildGoldDivider(),
                      ),
                      SizedBox(height: isMobile ? 12 : 20),

                      // ── Section Label ──
                      FadeTransition(
                        opacity: _cardsFade,
                        child: Text(
                          'SELECT YOUR PORTAL',
                          style: GoogleFonts.inter(
                            fontSize: isMobile ? 11 : 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textMuted.withValues(alpha: 0.6),
                            letterSpacing: 4,
                          ),
                        ),
                      ),
                      SizedBox(height: isMobile ? 24 : 36),

                      // ── Role Cards Grid ──
                      FadeTransition(
                        opacity: _cardsFade,
                        child: _buildCardsGrid(context, isMobile, isTablet),
                      ),
                      const SizedBox(height: 48),

                      // ── Footer ──
                      FadeTransition(
                        opacity: _cardsFade,
                        child: _buildFooter(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmbientOrb(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, color.withValues(alpha: 0)],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: AppTheme.primaryGold.withValues(alpha: 0.4 + 0.2 * sin(_shimmerController.value * 2 * pi)),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGold.withValues(alpha: 0.1 + 0.05 * sin(_shimmerController.value * 2 * pi)),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Container(
            margin: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  AppTheme.primaryGold.withValues(alpha: 0.15),
                  AppTheme.primaryBurgundy.withValues(alpha: 0.2),
                ],
              ),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 36,
              color: AppTheme.primaryGold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildTitle(bool isMobile) {
    return Column(
      children: [
        Text(
          'GOURMET BISTRO',
          textAlign: TextAlign.center,
          style: GoogleFonts.playfairDisplay(
            fontSize: isMobile ? 32 : 48,
            fontWeight: FontWeight.bold,
            color: AppTheme.pureWhite,
            letterSpacing: isMobile ? 4 : 8,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 4),
        AnimatedBuilder(
          animation: _shimmerController,
          builder: (context, child) {
            return ShaderMask(
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: const [
                    AppTheme.primaryGold,
                    Color(0xFFF5E6A3),
                    AppTheme.primaryGold,
                  ],
                  stops: [
                    (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                    _shimmerController.value,
                    (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                  ],
                ).createShader(bounds);
              },
              child: Text(
                'RESTAURANT  OPERATING  SYSTEM',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: isMobile ? 10 : 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.pureWhite,
                  letterSpacing: isMobile ? 4 : 6,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTagline(bool isMobile) {
    return Text(
      'Where every dish tells a story',
      textAlign: TextAlign.center,
      style: GoogleFonts.playfairDisplay(
        fontSize: isMobile ? 16 : 20,
        fontStyle: FontStyle.italic,
        color: AppTheme.textMuted.withValues(alpha: 0.7),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildGoldDivider() {
    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        return Container(
          width: 120,
          height: 1,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.primaryGold.withValues(alpha: 0),
                AppTheme.primaryGold.withValues(alpha: 0.4 + 0.3 * sin(_shimmerController.value * 2 * pi)),
                AppTheme.primaryGold.withValues(alpha: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCardsGrid(BuildContext context, bool isMobile, bool isTablet) {
    final cards = [
      _RoleCardData(
        icon: Icons.restaurant_menu_rounded,
        title: 'Order Food',
        subtitle: 'Browse the menu, place\nyour order & track it live',
        route: '/customer',
        accentColor: AppTheme.primaryGold,
        index: 0,
      ),
      _RoleCardData(
        icon: Icons.badge_rounded,
        title: 'Staff Portal',
        subtitle: 'For employees — manage\norders, kitchen & tables',
        route: '/login',
        accentColor: const Color(0xFF8B5CF6), // violet
        index: 1,
      ),
      _RoleCardData(
        icon: Icons.business_rounded,
        title: 'Owner Dashboard',
        subtitle: 'For business owners —\nanalytics, menu & revenue',
        route: '/login',
        accentColor: const Color(0xFF06B6D4), // cyan
        index: 2,
      ),
      _RoleCardData(
        icon: Icons.shield_rounded,
        title: 'Super Admin',
        subtitle: 'Platform management\n& system controls',
        route: '/login',
        accentColor: const Color(0xFFF59E0B), // amber
        index: 3,
      ),
    ];

    if (isMobile) {
      return Column(
        children: cards.map((card) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _RoleCard(data: card, isMobile: true),
          );
        }).toList(),
      );
    }

    // Desktop / Tablet: 2x2 grid
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 900),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _RoleCard(data: cards[0], isMobile: false)),
              const SizedBox(width: 20),
              Expanded(child: _RoleCard(data: cards[1], isMobile: false)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _RoleCard(data: cards[2], isMobile: false)),
              const SizedBox(width: 20),
              Expanded(child: _RoleCard(data: cards[3], isMobile: false)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Container(
          width: 40,
          height: 1,
          color: AppTheme.borderLight,
        ),
        const SizedBox(height: 16),
        Text(
          'Powered by RestaurantOS',
          style: GoogleFonts.inter(
            fontSize: 11,
            color: AppTheme.textMuted.withValues(alpha: 0.4),
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'v1.0.0',
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textMuted.withValues(alpha: 0.25),
          ),
        ),
      ],
    );
  }
}

// ── Data Model for Role Cards ──
class _RoleCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final Color accentColor;
  final int index;

  const _RoleCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.accentColor,
    required this.index,
  });
}

// ── Glassmorphism Role Card Widget ──
class _RoleCard extends StatefulWidget {
  final _RoleCardData data;
  final bool isMobile;

  const _RoleCard({required this.data, required this.isMobile});

  @override
  State<_RoleCard> createState() => _RoleCardState();
}

class _RoleCardState extends State<_RoleCard>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOutCubic),
    );
    _glowAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go(widget.data.route),
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnim.value,
              child: TiltedCard(
                rotateAmplitude: 10.0,
                child: Container(
                  padding: EdgeInsets.all(widget.isMobile ? 20 : 28),
                  decoration: BoxDecoration(
                    // Glassmorphism: semi-transparent dark panel
                    color: Color.lerp(
                      const Color(0xFF141414).withValues(alpha: 0.6),
                      const Color(0xFF1A1A2E).withValues(alpha: 0.8),
                      _glowAnim.value,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Color.lerp(
                        AppTheme.borderLight,
                        widget.data.accentColor.withValues(alpha: 0.5),
                        _glowAnim.value,
                      )!,
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: widget.data.accentColor.withValues(alpha: 0.08 * _glowAnim.value),
                        blurRadius: 30,
                        spreadRadius: 2,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: widget.isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Row(
      children: [
        _buildIconContainer(48, 24),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.data.title,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.pureWhite,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.data.subtitle.replaceAll('\n', ' '),
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textMuted,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _isHovered
                ? widget.data.accentColor.withValues(alpha: 0.15)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: _isHovered ? widget.data.accentColor : AppTheme.textMuted.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopLayout() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _buildIconContainer(56, 26),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered
                    ? widget.data.accentColor.withValues(alpha: 0.12)
                    : Colors.transparent,
              ),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: _isHovered ? widget.data.accentColor : AppTheme.textMuted.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text(
          widget.data.title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.pureWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.data.subtitle,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppTheme.textMuted,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        // Accent bar
        AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: _isHovered ? 48 : 24,
          height: 2,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(1),
            color: widget.data.accentColor.withValues(alpha: _isHovered ? 0.8 : 0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildIconContainer(double size, double iconSize) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _isHovered
            ? widget.data.accentColor.withValues(alpha: 0.12)
            : widget.data.accentColor.withValues(alpha: 0.06),
        border: Border.all(
          color: _isHovered
              ? widget.data.accentColor.withValues(alpha: 0.5)
              : widget.data.accentColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
      ),
      child: Icon(
        widget.data.icon,
        size: iconSize,
        color: widget.data.accentColor,
      ),
    );
  }
}
