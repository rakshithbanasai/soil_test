import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Services/LanguageProvider.dart';
import '../Utils/app_colors.dart';

/// Language selection screen shown on first launch or accessible from profile.
///
/// Presents two options — English and Kannada — with radio-button style
/// selection. Tapping "Continue" persists the choice and navigates to the
/// Dashboard.
class LanguageSelectionScreen extends StatefulWidget {
  final bool isFirstLaunch;

  const LanguageSelectionScreen({super.key, this.isFirstLaunch = true});

  @override
  State<LanguageSelectionScreen> createState() =>
      _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  String _selectedLanguage = LanguageCode.english;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // ---- App icon / branding ----
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: app_colors.primaryColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: app_colors.primaryColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.agriculture,
                  color: Colors.white,
                  size: 44,
                ),
              ),
              const SizedBox(height: 32),

              // ---- Title ----
              const Text(
                'Choose Language',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select your preferred language',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54, fontSize: 16),
              ),
              const SizedBox(height: 48),

              // ---- Language options ----
              _languageOption(
                code: LanguageCode.english,
                label: 'English',
                subtitle: 'Continue in English',
                flag: '🇬🇧',
              ),
              const SizedBox(height: 16),
              _languageOption(
                code: LanguageCode.kannada,
                label: 'ಕನ್ನಡ',
                subtitle: 'ಕನ್ನಡದಲ್ಲಿ ಮುಂದುವರಿಯಿರಿ',
                flag: '🇮🇳',
              ),

              const Spacer(flex: 2),

              // ---- Continue button ----
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () async {
                    final provider = Provider.of<LanguageProvider>(
                      context,
                      listen: false,
                    );
                    await provider.setLanguage(_selectedLanguage);

                    if (widget.isFirstLaunch) {
                      // First launch → replace with Dashboard
                      Navigator.pushReplacementNamed(context, '/dashboard');
                    } else {
                      // Returning from profile → just pop back
                      Navigator.pop(context);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Continue',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Single language option row.
  Widget _languageOption({
    required String code,
    required String label,
    required String subtitle,
    required String flag,
  }) {
    final isSelected = _selectedLanguage == code;

    return GestureDetector(
      onTap: () => setState(() => _selectedLanguage = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? app_colors.primaryColor.withOpacity(0.08)
              : Colors.grey[100],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? app_colors.primaryColor : Colors.grey[300]!,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            // Flag emoji
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            // Language name and subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? app_colors.primaryColor : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: isSelected ? app_colors.primaryColor : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            // Radio indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? app_colors.primaryColor : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? app_colors.primaryColor
                      : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
