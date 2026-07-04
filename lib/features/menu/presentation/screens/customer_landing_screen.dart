import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:io';

// StateProvider to track the scanned table ID
final selectedTableProvider = StateProvider<String?>((ref) => null);

class CustomerLandingScreen extends ConsumerStatefulWidget {
  const CustomerLandingScreen({super.key});

  @override
  ConsumerState<CustomerLandingScreen> createState() => _CustomerLandingScreenState();
}

class _CustomerLandingScreenState extends ConsumerState<CustomerLandingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _scannerAnimController;
  final _tableController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _scannerAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (kIsWeb || !Platform.environment.containsKey('FLUTTER_TEST')) {
      _scannerAnimController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _scannerAnimController.dispose();
    _tableController.dispose();
    super.dispose();
  }

  void _unlockTable(String tableId) {
    ref.read(selectedTableProvider.notifier).state = tableId;
    context.go('/customer/menu');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('BistroOS Gateway'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.go('/login'),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                'Welcome to Gourmet Bistro',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Scan the QR code on your table to browse the menu and order fresh food directly to your seat.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 40),

              // Animated Mock QR Scanner Viewfinder
              Center(
                child: SizedBox(
                  width: 240,
                  height: 240,
                  child: Stack(
                    children: [
                      // Viewfinder border corners
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400, width: 2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      // Animated scanning laser line
                      AnimatedBuilder(
                        animation: _scannerAnimController,
                        builder: (context, child) {
                          return Positioned(
                            top: _scannerAnimController.value * 220 + 10,
                            left: 15,
                            right: 15,
                            child: Container(
                              height: 3,
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary,
                                boxShadow: [
                                  BoxShadow(
                                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      // Styled mock QR icon inside the viewfinder
                      Center(
                        child: Icon(
                          Icons.qr_code_scanner,
                          size: 140,
                          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 36),

              // Simulate QR Scan button
              ElevatedButton.icon(
                key: const Key('simulateQrScanButton'),
                icon: const Icon(Icons.qr_code),
                label: const Text('Scan Table QR Code'),
                onPressed: () => _unlockTable('Table T-04'),
              ),
              const SizedBox(height: 24),

              // Divider
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text('OR', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              const SizedBox(height: 24),

              // Manual Table input form
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      key: const Key('tableNumberField'),
                      controller: _tableController,
                      keyboardType: TextInputType.text,
                      decoration: const InputDecoration(
                        labelText: 'Enter Table Number Manually',
                        hintText: 'e.g. Table 12',
                        prefixIcon: Icon(Icons.table_restaurant),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter a valid table number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    OutlinedButton(
                      key: const Key('manualTableSubmitButton'),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _unlockTable(_tableController.text.trim());
                        }
                      },
                      child: const Text('Enter Table'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
