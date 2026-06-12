import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Services/LanguageProvider.dart';
import 'Screens/SoilTest.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize the language provider (loads saved preference)
  final languageProvider = LanguageProvider();
  await languageProvider.init();

  runApp(
    ChangeNotifierProvider.value(
      value: languageProvider,
      child: const SoilTest(),
    ),
  );
}
