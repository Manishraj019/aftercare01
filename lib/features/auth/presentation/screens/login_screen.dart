import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // true = Sign In form active (Red panel on right)
  // false = Sign Up form active (Red panel on left)
  bool isSignIn = true; 
  String _selectedRole = 'Customer'; // 'Customer', 'Admin', 'Hotel'

  final _signInEmail = TextEditingController(text: 'admin@bistro.com');
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
        context.go('/owner/dashboard');
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message, style: GoogleFonts.inter(color: Colors.white)),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });

    // Make layout somewhat responsive, though the slider requires a minimum width
    final screenWidth = MediaQuery.of(context).size.width;
    final containerWidth = screenWidth > 800 ? 800.0 : screenWidth * 0.95;
    final halfWidth = containerWidth / 2;

    return Scaffold(
      backgroundColor: const Color(0xFF1F1F1F), // Dark background
      body: Center(
        child: Container(
          width: containerWidth,
          height: 550,
          clipBehavior: Clip.antiAlias, // Ensures the sliding panel doesn't draw outside corners
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 30,
                offset: const Offset(0, 15),
              )
            ]
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
              
              // 3. Animated Sliding Red Panel
              AnimatedPositioned(
                duration: const Duration(milliseconds: 600),
                curve: Curves.easeInOutCubic,
                left: isSignIn ? halfWidth : 0,
                top: 0,
                bottom: 0,
                width: halfWidth,
                child: _buildRedPanel(),
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
                        style: const TextStyle(color: Colors.blueAccent),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Sign In', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 16),
          Text('Sign in With $_selectedRole Account', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          _buildTextField(emailHint, controller: _signInEmail),
          _buildTextField('Enter Password', isPassword: true, controller: _signInPassword),
          const SizedBox(height: 16),
          Text('Forget Password?', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 24),
          _buildRedButton('SIGN IN', _performLogin),
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
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Create Account', style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.black)),
          const SizedBox(height: 16),
          _buildRoleSelector(),
          const SizedBox(height: 16),
          Text('Register as $_selectedRole', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 16),
          _buildTextField(nameHint, controller: _signUpName),
          _buildTextField(emailHint, controller: _signUpEmail),
          _buildTextField('Enter Password', isPassword: true, controller: _signUpPassword),
          const SizedBox(height: 24),
          _buildRedButton('SIGN UP', () {
            // Mock sign up success, slide back to login
            setState(() => isSignIn = true);
          }),
        ],
      ),
    );
  }

  Widget _buildRedPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFF416C), Color(0xFFFF4B2B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        )
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
        child: isSignIn ? _buildRedPanelRight() : _buildRedPanelLeft(),
      ),
    );
  }

  Widget _buildRedPanelRight() {
    return Padding(
      key: const ValueKey('right'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Hello World', style: GoogleFonts.poppins(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 16),
          Text(
            'Sign up now and enjoy our site',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildOutlineButton('SIGN UP', () => setState(() => isSignIn = false)),
        ],
      ),
    );
  }

  Widget _buildRedPanelLeft() {
    return Padding(
      key: const ValueKey('left'),
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Welcome To\nRestaurantOS',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 16),
          Text(
            'Sign in With Email & Password',
            style: GoogleFonts.inter(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w300),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          _buildOutlineButton('SIGN IN', () => setState(() => isSignIn = true)),
        ],
      ),
    );
  }

  Widget _buildTextField(String hint, {bool isPassword = false, required TextEditingController controller}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
          filled: true,
          fillColor: const Color(0xFFF3F4F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildSocialIcons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildSocialBtn('G'),
        const SizedBox(width: 12),
        _buildSocialBtn('f'),
        const SizedBox(width: 12),
        _buildSocialBtn('in'),
      ],
    );
  }

  Widget _buildRoleSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _buildRoleOption('Customer'),
          _buildRoleOption('Admin'),
          _buildRoleOption('Hotel'),
        ],
      ),
    );
  }

  Widget _buildRoleOption(String role) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]
                : [],
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: GoogleFonts.inter(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? Colors.black : Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSocialBtn(String text) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade300),
      ),
      alignment: Alignment.center,
      child: Text(
        text,
        style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
      ),
    );
  }

  Widget _buildRedButton(String text, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFF2B2B),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 0,
      ),
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }

  Widget _buildOutlineButton(String text, VoidCallback onPressed) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: Text(text, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
    );
  }
}
