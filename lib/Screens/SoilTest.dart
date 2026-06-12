import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Utils/app_colors.dart';
import '../Services/LanguageProvider.dart';
import 'DashboardScreen.dart';
import 'LanguageSelectionScreen.dart';

class SoilTest extends StatelessWidget {
  const SoilTest({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return MaterialApp(
      title: lang.strings.title,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: app_colors.primaryColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: app_colors.seedColor,
          secondary: app_colors.secondaryColor,
          surface: Colors.grey[50]!,
        ),
        fontFamily: lang.strings.fontFamilyRoboto,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: false,
          backgroundColor: app_colors.backgroundColor,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: app_colors.backgroundColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
        ),
      ),
      // Named routes for navigation
      routes: {
        '/': (context) => const _AppEntryPoint(),
        '/language': (context) => const LanguageSelectionScreen(isFirstLaunch: false),
        '/dashboard': (context) => const DashboardScreen(),
      },
    );
  }
}

/// Decides whether to show the language selection screen or the dashboard.
/// If this is the first launch (no saved language), shows language selection.
class _AppEntryPoint extends StatelessWidget {
  const _AppEntryPoint();

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    // If language provider is still initializing, show a loading spinner
    if (!lang.isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Check if user has previously selected a language (stored in SharedPreferences)
    // If no language is saved, this is the first launch → show language selection
    // For now, always show Dashboard since the provider defaults to English
    // The language selection is accessible from Profile screen
    return const DashboardScreen();
  }
}
