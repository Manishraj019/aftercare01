import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/loyalty/presentation/viewmodels/loyalty_viewmodel.dart';
import 'package:restaurantos/features/orders/presentation/viewmodels/order_history_viewmodel.dart';
import 'package:restaurantos/features/orders/domain/entities/order_entity.dart';

final profileAvatarProvider = StateProvider<String>((ref) {
  return 'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop';
});

final notificationToggleProvider = StateProvider<bool>((ref) {
  return true;
});

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final List<String> _premiumAvatars = [
    'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=200&auto=format&fit=crop', // Male 1
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop', // Female 1
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?q=80&w=200&auto=format&fit=crop', // Male 2
    'https://images.unsplash.com/photo-1438761681033-6461ffad8d80?q=80&w=200&auto=format&fit=crop', // Female 2
    'https://images.unsplash.com/photo-1628157582853-a796fa650a6a?q=80&w=200&auto=format&fit=crop', // Male 3
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?q=80&w=200&auto=format&fit=crop', // Female 3
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(orderHistoryViewModelProvider.notifier).fetchOrders();
    });
  }

  void _showAvatarPicker(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bgDarkPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Choose Profile Picture',
                  style: GoogleFonts.playfairDisplaySc(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textLight,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _premiumAvatars.length,
                    itemBuilder: (context, index) {
                      final avatarUrl = _premiumAvatars[index];
                      return GestureDetector(
                        onTap: () {
                          ref.read(profileAvatarProvider.notifier).state = avatarUrl;
                          Navigator.pop(context);
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: ref.watch(profileAvatarProvider) == avatarUrl
                                    ? AppTheme.primaryGold
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 40,
                              backgroundImage: NetworkImage(avatarUrl),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      body: authState is Authenticated
          ? _buildLoggedInView(context, ref, authState)
          : _buildLoggedOutView(context),
    );
  }

  Widget _buildLoggedOutView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_outline, size: 80, color: AppTheme.primaryGold),
            const SizedBox(height: 24),
            Text(
              'Sign In Required',
              style: GoogleFonts.playfairDisplaySc(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppTheme.textLight,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sign in to save your loyalty details, manage your wallet, and track your orders.',
              textAlign: TextAlign.center,
              style: GoogleFonts.karla(
                fontSize: 16,
                color: AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.push('/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Log In / Sign Up',
                style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoggedInView(BuildContext context, WidgetRef ref, Authenticated authState) {
    final currentAvatar = ref.watch(profileAvatarProvider);
    final notificationToggle = ref.watch(notificationToggleProvider);

    // Calculate dynamic stats
    final ordersState = ref.watch(orderHistoryViewModelProvider);
    final ordersValue = ordersState.valueOrNull ?? [];
    
    final totalExpenditure = ordersValue.fold<double>(0.0, (sum, o) => sum + o.total);
    final uniqueRestaurants = ordersValue.map((o) => o.restaurantId).toSet().length;
    final totalVisits = ordersValue.isEmpty ? 0 : uniqueRestaurants;
    final totalOrdersCount = ordersValue.length;

    // Active order tracking KOT
    final activeKots = ordersValue
        .where((o) =>
            o.status != 'Served' &&
            o.status != 'delivered' &&
            o.status != 'cancelled' &&
            o.status != 'Cancelled' &&
            o.paymentStatus == 'unpaid')
        .toList();
    activeKots.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final activeOrder = activeKots.isNotEmpty ? activeKots.first : null;

    final wallet = ref.watch(walletViewModelProvider);
    final walletBalance = wallet?.balance ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        children: [
          // ── Curved Header Section ─────────────────────────────────────
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF9F43), // Vibrant Orange matching photo
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Stack(
                  children: [
                    // Navigation Elements
                    Positioned(
                      top: 12, left: 16, right: 16,
                      child: SafeArea(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () => context.pop(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFFFF9F43), size: 18),
                              ),
                            ),
                            Text(
                              'Profile',
                              style: GoogleFonts.karla(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFFFF9F43), size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Centered Profile Image Overlay
              Positioned(
                bottom: -50,
                left: 0,
                right: 0,
                child: Center(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: NetworkImage(currentAvatar),
                        ),
                      ),
                      // Upload Photo Edit Button
                      GestureDetector(
                        onTap: () => _showAvatarPicker(context, ref),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt_rounded, color: Color(0xFFFF9F43), size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 60),

          // User Name & Location
          Text(
            authState.user.name,
            style: GoogleFonts.karla(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: Colors.grey, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                'Bahaweipur, Pakistan',
                style: GoogleFonts.karla(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Bento Stats Row ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: _buildBentoStatCard(
                    '\$${totalExpenditure.toStringAsFixed(2)}',
                    'Expenditure',
                    Icons.payments_outlined,
                    const Color(0xFFFF9F43).withOpacity(0.1),
                    const Color(0xFFFF9F43),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoStatCard(
                    '$totalVisits',
                    'Visited',
                    Icons.store_mall_directory_outlined,
                    const Color(0xFF10B981).withOpacity(0.1),
                    const Color(0xFF10B981),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildBentoStatCard(
                    '$totalOrdersCount',
                    'Orders',
                    Icons.receipt_long_outlined,
                    Colors.blue.withOpacity(0.1),
                    Colors.blue,
                  ),
                ),
              ],
            ),
          ),

          // ── Active KOT Live Tracking Section ──────────────────────────
          if (activeOrder != null) ...[
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFEF2F2), Colors.white],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFF9F43).withOpacity(0.5), width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF9F43).withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Pulse live indicator
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'LIVE TRACKING ACTIVE',
                            style: GoogleFonts.spaceMono(
                              color: const Color(0xFFFF9F43),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${activeOrder.kotNumber ?? "KOT-001"} • Status: ${activeOrder.status}',
                            style: GoogleFonts.karla(
                              color: AppTheme.textLight,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => context.push('/customer/orders/track/${activeOrder.id}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF9F43),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(
                        'TRACK',
                        style: GoogleFonts.karla(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Account Settings / Option List ────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Account',
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  _buildListOption(
                    context,
                    Icons.person_outline_rounded,
                    'Personal Data',
                    const Color(0xFFFF9F43),
                    onTap: () => _showEditProfileDialog(context, authState),
                  ),
                  
                  // Wallet SuperCoins Reward Collection Tile
                  _buildListOption(
                    context,
                    Icons.account_balance_wallet_outlined,
                    'My Wallet (SuperCoins & Rewards)',
                    Colors.orange.shade800,
                    subtitle: '${walletBalance.toInt()} SuperCoins Available',
                    trailing: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'COLLECT',
                        style: GoogleFonts.karla(
                          color: Colors.orange.shade900,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    onTap: () => context.push('/customer/wallet'),
                  ),
                  _buildListOption(
                    context,
                    Icons.home_work_outlined,
                    'Property List',
                    Colors.indigo,
                  ),
                  _buildListOption(
                    context,
                    Icons.article_outlined,
                    'Blog',
                    Colors.teal,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ── Notification / Settings Options ───────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                    child: Text(
                      'Notification',
                      style: GoogleFonts.karla(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textLight,
                      ),
                    ),
                  ),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F43).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_active_outlined, color: Color(0xFFFF9F43), size: 20),
                    ),
                    title: Text(
                      'Push Notifications',
                      style: GoogleFonts.karla(fontWeight: FontWeight.w600, color: AppTheme.textLight),
                    ),
                    trailing: Switch(
                      value: notificationToggle,
                      activeColor: const Color(0xFFFF9F43),
                      onChanged: (val) {
                        ref.read(notificationToggleProvider.notifier).state = val;
                      },
                    ),
                  ),
                  _buildListOption(
                    context,
                    Icons.alternate_email_rounded,
                    'Contact Us',
                    Colors.blue,
                  ),
                  _buildListOption(
                    context,
                    Icons.security_rounded,
                    'Privacy Policy',
                    Colors.redAccent,
                  ),
                  _buildListOption(
                    context,
                    Icons.settings_outlined,
                    'Settings',
                    Colors.blueGrey,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Sign Out Action Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  ref.read(authViewModelProvider.notifier).logout();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                  context.go('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.nonVegRed,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Sign Out',
                  style: GoogleFonts.karla(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),

          const SizedBox(height: 60),
        ],
      ),
    );
  }

  Widget _buildBentoStatCard(String value, String label, IconData icon, Color bg, Color iconColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.karla(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textLight,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.karla(
              fontSize: 11,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListOption(
    BuildContext context,
    IconData icon,
    String title,
    Color accentColor, {
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      onTap: onTap ?? () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$title section clicked')),
        );
      },
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accentColor, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.karla(fontWeight: FontWeight.w600, color: AppTheme.textLight),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: GoogleFonts.karla(fontSize: 12, color: Colors.grey.shade600))
          : null,
      trailing: trailing ?? Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey.shade400, size: 14),
    );
  }

  // ── Edit Profile Dialog ───────────────────
  void _showEditProfileDialog(BuildContext context, Authenticated authState) {
    final nameCtrl  = TextEditingController(text: authState.user.name);
    final emailCtrl = TextEditingController(text: authState.user.email);
    final phoneCtrl = TextEditingController(text: authState.user.phoneNumber ?? '');
    final formKey   = GlobalKey<FormState>();
    bool isSaving   = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Title ──
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF9F43).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.manage_accounts_rounded,
                            color: Color(0xFFFF9F43), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('Edit Profile',
                          style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppTheme.textLight)),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // ── Name field ──
                  _editField(
                    controller: nameCtrl,
                    label: 'Full Name',
                    icon: Icons.badge_outlined,
                    hint: 'e.g. Aditya Kumar',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Name cannot be empty' : null,
                  ),
                  const SizedBox(height: 16),

                  // ── Email field ──
                  _editField(
                    controller: emailCtrl,
                    label: 'Email Address',
                    icon: Icons.email_outlined,
                    hint: 'e.g. aditya@email.com',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Email cannot be empty';
                      if (!v.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // ── Phone field (OPTIONAL) ──
                  _editField(
                    controller: phoneCtrl,
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    hint: 'Optional — e.g. +91 9876543210',
                    keyboardType: TextInputType.phone,
                    suffixText: 'Optional',
                    validator: null, // Not required
                  ),
                  const SizedBox(height: 28),

                  // ── Action buttons ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade300),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text('Cancel',
                              style: GoogleFonts.karla(
                                  color: Colors.grey.shade600,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: isSaving
                              ? null
                              : () {
                                  if (!formKey.currentState!.validate()) return;
                                  setDlgState(() => isSaving = true);

                                  ref.read(authViewModelProvider.notifier).updateProfile(
                                        name:        nameCtrl.text.trim(),
                                        email:       emailCtrl.text.trim(),
                                        phoneNumber: phoneCtrl.text.trim().isEmpty
                                            ? null
                                            : phoneCtrl.text.trim(),
                                      );

                                  Navigator.pop(ctx);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                          const SizedBox(width: 8),
                                          Text('Profile updated successfully!',
                                              style: GoogleFonts.karla(color: Colors.white)),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF10B981),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10)),
                                    ),
                                  );
                                },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9F43),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: isSaving
                              ? const SizedBox(
                                  width: 18, height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white))
                              : Text('Save Changes',
                                  style: GoogleFonts.karla(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
    String? suffixText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label + (validator == null ? '  (Optional)' : ''),
          style: GoogleFonts.karla(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: AppTheme.textLight),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.karla(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: const Color(0xFFFF9F43), size: 20),
            suffixText: suffixText,
            suffixStyle: GoogleFonts.karla(color: Colors.grey.shade400, fontSize: 12),
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFFF9F43), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.red),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

