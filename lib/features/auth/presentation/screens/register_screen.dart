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
      backgroundColor: Theme.of(context).colorScheme.primary, // Red background
      appBar: AppBar(
        title: const Text(AppLocalizations.registerLink),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Container(
              padding: const EdgeInsets.all(32.0),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Theme.of(context).colorScheme.onSurface, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black26, offset: Offset(8, 8)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      AppLocalizations.registerTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                            fontSize: 28,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalizations.registerSubtitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 32),

                    // Name Input
                    TextFormField(
                      controller: _nameController,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: AppLocalizations.nameLabel,
                        hintText: AppLocalizations.nameHint,
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.fieldRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Email Input
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: AppLocalizations.emailLabel,
                        hintText: AppLocalizations.emailHint,
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.fieldRequired;
                        if (!value.contains('@')) return AppLocalizations.invalidEmail;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Password Input
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: AppLocalizations.passwordLabel,
                        hintText: AppLocalizations.passwordHint,
                        prefixIcon: Icon(Icons.lock_outline),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) return AppLocalizations.fieldRequired;
                        if (value.length < 6) return AppLocalizations.invalidPassword;
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Phone Input
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      enabled: !isLoading,
                      decoration: const InputDecoration(
                        labelText: AppLocalizations.phoneLabel,
                        hintText: AppLocalizations.phoneHint,
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Dynamic Restaurant / Shop Name for Owner
                    if (_selectedRole == 'owner') ...[
                      TextFormField(
                        controller: _shopNameController,
                        enabled: !isLoading,
                        decoration: const InputDecoration(
                          labelText: 'Restaurant / Shop Name',
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
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Customer'),
                          selected: _selectedRole == 'customer',
                          onSelected: isLoading ? null : (selected) {
                            if (selected) setState(() => _selectedRole = 'customer');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Owner'),
                          selected: _selectedRole == 'owner',
                          onSelected: isLoading ? null : (selected) {
                            if (selected) setState(() => _selectedRole = 'owner');
                          },
                        ),
                        ChoiceChip(
                          label: const Text('Admin'),
                          selected: _selectedRole == 'admin',
                          onSelected: isLoading ? null : (selected) {
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
                          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
