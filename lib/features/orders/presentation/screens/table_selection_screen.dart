import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:restaurantos/core/theme/app_theme.dart';

class TableSelectionScreen extends StatefulWidget {
  const TableSelectionScreen({super.key});

  @override
  State<TableSelectionScreen> createState() => _TableSelectionScreenState();
}

class _TableSelectionScreenState extends State<TableSelectionScreen> {
  String _enteredTable = '';

  void _onKeyPress(String val) {
    if (_enteredTable.length < 3) {
      setState(() {
        _enteredTable += val;
      });
    }
  }

  void _onBackspace() {
    if (_enteredTable.isNotEmpty) {
      setState(() {
        _enteredTable = _enteredTable.substring(0, _enteredTable.length - 1);
      });
    }
  }

  void _onContinue() {
    if (_enteredTable.isNotEmpty) {
      // Proceed to menu with table context
      context.go('/customer/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgDarkCharcoal,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Where are you seated?',
                style: GoogleFonts.playfairDisplaySc(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.pureWhite,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your table number to view the menu.',
                style: GoogleFonts.karla(
                  color: AppTheme.textMuted,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Center(
                child: Container(
                  width: 150,
                  height: 100,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.bgDarkPanel,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _enteredTable.isEmpty ? AppTheme.borderLight : AppTheme.primaryGold,
                      width: 2,
                    ),
                  ),
                  child: Text(
                    _enteredTable.isEmpty ? '-' : _enteredTable,
                    style: GoogleFonts.karla(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: _enteredTable.isEmpty ? AppTheme.textMuted : AppTheme.primaryGold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              // Custom Numpad
              Expanded(
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 1.5,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 12,
                  itemBuilder: (context, index) {
                    if (index == 9) {
                      return const SizedBox.shrink();
                    } else if (index == 10) {
                      return _buildNumpadButton('0');
                    } else if (index == 11) {
                      return _buildBackspaceButton();
                    }
                    return _buildNumpadButton('${index + 1}');
                  },
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _enteredTable.isEmpty ? null : _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGold,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: AppTheme.bgDarkPanel,
                  disabledForegroundColor: AppTheme.textMuted,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  'Continue',
                  style: GoogleFonts.karla(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpadButton(String label) {
    return InkWell(
      onTap: () => _onKeyPress(label),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.bgDarkPanel,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderLight.withValues(alpha: 0.5)),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.karla(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: AppTheme.pureWhite,
          ),
        ),
      ),
    );
  }

  Widget _buildBackspaceButton() {
    return InkWell(
      onTap: _onBackspace,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        alignment: Alignment.center,
        child: const Icon(
          Icons.backspace_outlined,
          color: AppTheme.pureWhite,
          size: 28,
        ),
      ),
    );
  }
}
