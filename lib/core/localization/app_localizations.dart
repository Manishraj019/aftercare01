class AppLocalizations {
  // Login Screen
  static const String loginTitle = 'Welcome to RestaurantOS';
  static const String loginSubtitle = 'Sign in to access your workspace';
  static const String emailLabel = 'Email Address';
  static const String emailHint = 'enter your email';
  static const String passwordLabel = 'Password';
  static const String passwordHint = 'enter your password';
  static const String loginButton = 'Sign In';
  static const String registerPrompt = "Don't have an account? ";
  static const String registerLink = 'Sign Up';
  static const String loginWithGoogle = 'Sign in with Google';
  static const String loginWithOtp = 'Sign in with Phone (OTP)';
  static const String selectRole = 'Select Workspace Role';

  // Registration Screen
  static const String registerTitle = 'Create Account';
  static const String registerSubtitle = 'Join RestaurantOS and set up your workspace';
  static const String nameLabel = 'Full Name';
  static const String nameHint = 'enter your full name';
  static const String phoneLabel = 'Phone Number';
  static const String phoneHint = 'e.g. +1234567890';
  static const String registerButton = 'Create Account';
  static const String loginPrompt = 'Already have an account? ';
  static const String loginLink = 'Sign In';

  // OTP Screen
  static const String otpTitle = 'Phone Verification';
  static const String otpSubtitle = 'We sent a verification code to your number';
  static const String verifyButton = 'Verify & Proceed';
  static const String resendButton = 'Resend Code';
  static const String codeLabel = 'Verification Code';
  static const String codeHint = 'enter 6-digit code';

  // Validation & States
  static const String loadingText = 'Please wait...';
  static const String fieldRequired = 'This field is required';
  static const String invalidEmail = 'Please enter a valid email';
  static const String invalidPassword = 'Password must be at least 6 characters';
  static const String invalidPhone = 'Enter valid phone number (with country code)';
  static const String invalidOtp = 'OTP must be 6 digits';
}
