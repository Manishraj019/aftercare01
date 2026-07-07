import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/food_app_widgets.dart';

final selectedTableProvider = StateProvider<String?>((ref) => null);

class CustomerLandingScreen extends ConsumerStatefulWidget {
  const CustomerLandingScreen({super.key});

  @override
  ConsumerState<CustomerLandingScreen> createState() => _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends ConsumerState<CustomerLandingScreen> {
  final _tableController = TextEditingController();

  @override
  void dispose() {
    _tableController.dispose();
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
    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      body: Stack(
        children: [
          // Elegant Background with subtle gradient
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.topCenter,
                radius: 1.5,
                colors: [
                  AppTheme.bgDeepBurgundy,
                  AppTheme.bgDarkCharcoal,
                ],
                stops: const [0.0, 1.0],
              ),
            ),
          ),

          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Mock logo/icon
                  Container(
                    width: 120, height: 120,
                    decoration: BoxDecoration(
                      color: AppTheme.bgDarkPanel.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.primaryGold, width: 2),
                      boxShadow: [
                        BoxShadow(color: AppTheme.primaryGold.withValues(alpha: 0.2), blurRadius: 30, spreadRadius: 5)
                      ],
                    ),
                    child: const Icon(Icons.restaurant_menu_rounded, size: 64, color: AppTheme.primaryGold),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Gourmet Bistro',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48, fontWeight: FontWeight.bold, color: AppTheme.primaryGold, letterSpacing: 2.0
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Experience culinary excellence.',
                    style: GoogleFonts.inter(
                      fontSize: 18, color: AppTheme.textLight, letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 48),

                  GlassContainer(
                    blur: 20, opacity: 0.6,
                    padding: const EdgeInsets.all(32),
                    child: SizedBox(
                      width: 320,
                      child: Column(
                        children: [
                          Text(
                            'Dine-in?',
                            style: GoogleFonts.playfairDisplay(fontSize: 24, fontWeight: FontWeight.w600, color: AppTheme.pureWhite),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Enter your table number or scan the QR code on your table.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textMuted, height: 1.5),
                          ),
                          const SizedBox(height: 32),
                          TextField(
                            controller: _tableController,
                            style: GoogleFonts.inter(color: AppTheme.pureWhite, fontSize: 18, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Table Number (e.g., 5)',
                              hintStyle: GoogleFonts.inter(color: AppTheme.textMuted, fontSize: 14, fontWeight: FontWeight.normal),
                              prefixIcon: const Icon(Icons.table_bar_rounded, color: AppTheme.primaryGold),
                              filled: true,
                              fillColor: AppTheme.bgDarkPanel.withValues(alpha: 0.8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
                              ),
                            ),
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            child: FoodPrimaryButton(
                              onPressed: () => _proceed(context, ref),
                              label: 'VIEW MENU',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
