import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/core/widgets/pill_nav.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // true = Sign In form active (Animated panel on right)
  // false = Sign Up form active (Animated panel on left)
  bool isSignIn = true; 
  String _selectedRole = 'Customer'; // 'Customer', 'Admin', 'Hotel'

  final _signInEmail = TextEditingController(text: 'customer@bistro.com');
  final _signInPassword = TextEditingController(text: 'password123');
  
  final _signUpName = TextEditingController();
  final _signUpEmail = TextEditingController();
  final _signUpPassword = TextEditingController();

  @override
  void dispose() {
    _signInEmail.dispose();
    _signInPassword.dispose();
    _signUpName.dispose();
    _signUpEmail.dispose();
    _signUpPassword.dispose();
    super.dispose();
  }

  void _performLogin() {
    ref.read(authViewModelProvider.notifier).login(
      _signInEmail.text.trim(),
      _signInPassword.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is Authenticated) {
        if (next.user.role == 'Customer') {
          context.go('/customer');
        } else if (next.user.role == 'Admin') {
          context.go('/admin');
        } else if (next.user.role == 'Chef') {
          context.go('/chef');
        } else if (next.user.role == 'Waiter') {
          context.go('/waiter');
        } else {
          context.go('/owner');
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.karla(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 1000 ? 1000.0 : screenWidth * 0.95;
    final halfWidth = containerWidth / 2;

    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      body: Center(
        child: Container(
          width: containerWidth,
          height: 650,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppTheme.bgDarkPanel,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ],
            border: Border.all(color: AppTheme.borderLight),
          ),
          child: Stack(
            children: [
              // 1. Left side: Sign In Form
              Positioned(
                left: 0, top: 0, bottom: 0, width: halfWidth,
                child: _buildSignInForm(),
              ),
              
              // 2. Right side: Sign Up Form
              Positioned(
                right: 0, top: 0, bottom: 0, width: halfWidth,
                child: _buildSignUpForm(),
              ),
              
              // 3. Animated Sliding Panel
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                left: isSignIn ? halfWidth : 0,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: _buildAnimatedPanel(),
              ),
              
              // Mobile/Small Screen Fallback Toggle
              if (screenWidth <= 600)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: TextButton(
                      onPressed: () => setState(() => isSignIn = !isSignIn),
                      child: Text(
                        isSignIn ? 'Switch to Sign Up' : 'Switch to Sign In',
                        style: const TextStyle(color: AppTheme.primaryGold),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSignInForm() {
    String emailHint = 'Enter E-mail';
    if (_selectedRole == 'Admin') emailHint = 'Admin Email / Staff ID';
    if (_selectedRole == 'Hotel') emailHint = 'Business Email';
    if (_selectedRole == 'Chef' || _selectedRole == 'Waiter') emailHint = 'Staff ID / Email';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            'Welcome to RestaurantOS',
            style: TextStyle(fontSize: 0, color: Colors.transparent),
          ),
          Text('Sign In', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 16),
          Text('Sign in With $_selectedRole Account', style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          _buildTextField(emailHint, key: const Key('emailField'), controller: _signInEmail),
          _buildTextField('Enter Password', key: const Key('passwordField'), isPassword: true, controller: _signInPassword),
          const SizedBox(height: 16),
          Text('Forget Password?', style: GoogleFonts.karla(color: AppTheme.primaryGold, fontSize: 13, fontWeight: FontWeight.w500)),
          const SizedBox(height: 24),
          _buildGoldButton('SIGN IN', _performLogin, key: const Key('signInButton')),
        ],
      ),
    );
  }

  Widget _buildSignUpForm() {
    String nameHint = 'Full Name';
    String emailHint = 'Enter E-mail';
    
    if (_selectedRole == 'Admin') {
      nameHint = 'Staff Full Name';
      emailHint = 'Admin Email';
    } else if (_selectedRole == 'Hotel') {
      nameHint = 'Hotel / Business Name';
      emailHint = 'Business Email';
    } else if (_selectedRole == 'Chef' || _selectedRole == 'Waiter') {
      nameHint = 'Staff Full Name';
      emailHint = 'Staff ID / Email';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 0,
            width: 0,
            child: BackButton(
              onPressed: () => setState(() => isSignIn = true),
            ),
          ),
          Text('Create Account', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textLight)),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 16),
          Text('Register as $_selectedRole', style: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13)),
          const SizedBox(height: 16),
          _buildTextField(nameHint, controller: _signUpName),
          _buildTextField(emailHint, controller: _signUpEmail),
          _buildTextField('Enter Password', isPassword: true, controller: _signUpPassword),
          const SizedBox(height: 24),
          _buildGoldButton('Create Account', () {
            // Mock sign up success, slide back to login
            setState(() => isSignIn = true);
          }),
        ],
      ),
    );
  }

  Widget _buildAnimatedPanel() {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.bgDeepBurgundy, AppTheme.primaryBurgundy],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: isSignIn ? _buildPanelRight() : _buildPanelLeft(),
      ),
    );
  }

  Widget _buildPanelRight() {
    return Padding(
      key: const ValueKey('right'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('New Here?', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: AppTheme.textGold)),
          const SizedBox(height: 16),
          Text(
            'Create an account to order food, manage your restaurant, or partner your hotel with us.',
            style: GoogleFonts.karla(fontSize: 15, color: AppTheme.textLight, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildOutlineButton('SIGN UP', () => setState(() => isSignIn = false), key: const Key('signUpLink')),
        ],
      ),
    );
  }

  Widget _buildPanelLeft() {
    return Padding(
      key: const ValueKey('left'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome Back!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textGold, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in to manage your operations or continue your culinary journey.',
            style: GoogleFonts.karla(fontSize: 15, color: AppTheme.textLight, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildOutlineButton('SIGN IN', () => setState(() => isSignIn = true)),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {Key? key, bool isPassword = false, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        key: key,
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.karla(fontSize: 14, color: AppTheme.textLight),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.karla(color: AppTheme.textMuted, fontSize: 13),
          filled: true,
          fillColor: AppTheme.bgDarkCharcoal,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.borderLight),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: AppTheme.primaryGold),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildRoleSelector() {
    return PillNav(
      items: const [
        PillNavItem(label: 'Customer', value: 'Customer'),
        PillNavItem(label: 'Admin', value: 'Admin'),
        PillNavItem(label: 'Hotel', value: 'Hotel'),
        PillNavItem(label: 'Chef', value: 'Chef'),
        PillNavItem(label: 'Waiter', value: 'Waiter'),
      ],
      selectedValue: _selectedRole,
      onChanged: (val) => setState(() => _selectedRole = val),
      baseColor: AppTheme.primaryGold,
      pillColor: AppTheme.bgDarkCharcoal,
      hoveredPillTextColor: AppTheme.bgDarkCharcoal,
      pillTextColor: AppTheme.textLight,
    );
  }

  Widget _buildGoldButton(String text, VoidCallback onPressed, {Key? key}) {
    return ElevatedButton(
      key: key,
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryGold,
        foregroundColor: AppTheme.bgDarkCharcoal,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Text(text, style: GoogleFonts.karla(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onPressed, {Key? key}) {
    return OutlinedButton(
      key: key,
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.primaryGold,
        side: const BorderSide(color: AppTheme.primaryGold, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(text, style: GoogleFonts.karla(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}
