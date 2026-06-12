import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soil_test/Utils/app_colors.dart';
import 'package:soil_test/Services/LanguageProvider.dart';

import 'ReportScreen.dart';

class ProcessingScreen extends StatefulWidget {
  const ProcessingScreen({super.key});

  @override
  State<ProcessingScreen> createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    // Set initial status after first frame so provider is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final s = Provider.of<LanguageProvider>(context, listen: false).strings;
        setState(() => _status = s.uploadingData);
        _startMockAnalysis();
      }
    });
  }

  void _startMockAnalysis() async {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _status = s.runningVisionModels);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _status = s.analysingNpkMoisture);

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _status = s.generatingSoilReport);

    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ReportScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageProvider>(context).strings;

    return Scaffold(
      backgroundColor: app_colors.primaryColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 32),
              Text(
                s.processingSoilData,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
