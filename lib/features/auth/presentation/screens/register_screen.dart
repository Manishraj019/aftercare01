import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:restaurantos/core/localization/app_localizations.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_state.dart';
import 'package:restaurantos/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String? initialRole;
  const RegisterScreen({super.key, this.initialRole});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole ?? 'customer';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _shopNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final nameValue = _selectedRole == 'owner'
          ? '${_nameController.text.trim()} | ${_shopNameController.text.trim()}'
          : _nameController.text.trim();

      ref.read(authViewModelProvider.notifier).register(
            name: nameValue,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            role: _selectedRole,
            phoneNumber: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);

    // Redirect or show error
    ref.listen<AuthState>(authViewModelProvider, (previous, next) {
      if (next is Authenticated) {
        final role = next.user.role;
        if (role == 'admin') {
          context.go('/admin');
        } else if (role == 'owner') {
          context.go('/owner');
        } else {
          context.go('/customer');
        }
      } else if (next is AuthError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.message),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isLoading = authState is AuthLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppLocalizations.registerLink),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    AppLocalizations.registerTitle,
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.registerSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 32),

                  // Name Input
                  Text(
                    AppLocalizations.nameLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: AppLocalizations.nameHint,
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Input
                  Text(
                    AppLocalizations.emailLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: AppLocalizations.emailHint,
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.fieldRequired;
                      }
                      if (!value.contains('@')) {
                        return AppLocalizations.invalidEmail;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Input
                  Text(
                    AppLocalizations.passwordLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: AppLocalizations.passwordHint,
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.fieldRequired;
                      }
                      if (value.length < 6) {
                        return AppLocalizations.invalidPassword;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Input
                  Text(
                    AppLocalizations.phoneLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    enabled: !isLoading,
                    decoration: const InputDecoration(
                      hintText: AppLocalizations.phoneHint,
                      prefixIcon: Icon(Icons.phone_outlined),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Dynamic Restaurant / Shop Name for Owner
                  if (_selectedRole == 'owner') ...[
                    const Text(
                      'Restaurant / Shop Name',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _shopNameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        hintText: 'Enter restaurant/shop name',
                        prefixIcon: Icon(Icons.storefront_outlined),
                      ),
                      validator: (value) {
                        if (_selectedRole == 'owner' && (value == null || value.isEmpty)) {
                          return 'Restaurant name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Role Selection chips
                  Text(
                    AppLocalizations.selectRole,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ChoiceChip(
                        label: const Text('Customer'),
                        selected: _selectedRole == 'customer',
                        onSelected: isLoading
                            ? null
                            : (selected) {
                                if (selected) setState(() => _selectedRole = 'customer');
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Owner'),
                        selected: _selectedRole == 'owner',
                        onSelected: isLoading
                            ? null
                            : (selected) {
                                if (selected) setState(() => _selectedRole = 'owner');
                              },
                      ),
                      ChoiceChip(
                        label: const Text('Admin'),
                        selected: _selectedRole == 'admin',
                        onSelected: isLoading
                            ? null
                            : (selected) {
                                if (selected) setState(() => _selectedRole = 'admin');
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // Register Button
                  ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(AppLocalizations.registerButton),
                  ),
                  const SizedBox(height: 32),

                  // Sign In Redirect Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(AppLocalizations.loginPrompt),
                      GestureDetector(
                        onTap: isLoading ? null : () => context.pop(),
                        child: Text(
                          AppLocalizations.loginLink,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
