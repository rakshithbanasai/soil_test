import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:soil_test/Screens/RegistrationScreen.dart';
import 'package:soil_test/Screens/LanguageSelectionScreen.dart';
import 'package:soil_test/Services/LanguageProvider.dart';
import 'package:soil_test/Utils/app_colors.dart';

import 'LoginScreen.dart';
import 'NewAnalysisScreen.dart';
import 'ProfileScreen.dart';
import 'ReportScreen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh profile data when dashboard loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context);
    final s = lang.strings;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          s.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          // Language toggle button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const LanguageSelectionScreen(
                    isFirstLaunch: false,
                  ),
                ),
              ).then((_) => setState(() {}));
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.language, color: Colors.white, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      lang.isKannada ? 'ಕನ್ನಡ' : 'EN',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProfileScreen(),
                  ),
                ).then((_) => setState(() {})); // Refresh on return
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginScreen()),
                ).then((_) => setState(() {})); // Refresh on return
              }
            },
            child: Padding(
              padding: const EdgeInsets.only(right: 12.0),
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user?.uid)
                    .get(),
                builder: (context, snapshot) {
                  String? photoUrl;
                  if (snapshot.hasData && snapshot.data!.exists) {
                    photoUrl = (snapshot.data!.data()
                        as Map<String, dynamic>?)?['photoUrl'] as String?;
                  }

                  return CircleAvatar(
                    radius: 18,
                    backgroundColor: Colors.white.withOpacity(0.3),
                    backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                        ? NetworkImage(photoUrl)
                        : null,
                    child: (photoUrl == null || photoUrl.isEmpty)
                        ? const Icon(Icons.person, color: Colors.white, size: 22)
                        : null,
                  );
                },
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Greeting Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [app_colors.primaryColor, Color(0xFF4CAF50)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(FirebaseAuth.instance.currentUser?.uid)
                        .get(),
                    builder: (context, snapshot) {
                      String name = s.guest;
                      if (snapshot.hasData && snapshot.data!.exists) {
                        name =
                            '${snapshot.data!['firstName']} ${snapshot.data!['lastName'] ?? "User"}';
                      }
                      return Text(
                        '${s.welcomeBack} $name!',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    s.farmHealthGood,
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const NewAnalysisScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.science,
                      color: app_colors.primaryColor,
                    ),
                    label: Text(
                      s.soilAnalysis,
                      style: TextStyle(
                        color: app_colors.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Text(
              s.recentReports,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // Mock History List
            _buildHistoryCard(
              context,
              'kumara krupa - #14/1',
              'April 10, 2026',
              s.optimalStatus,
              Colors.green,
            ),
            _buildHistoryCard(
              context,
              'kumara krupa - #15/1',
              'March 22, 2026',
              s.needsNitrogen,
              Colors.orange,
            ),
            _buildHistoryCard(
              context,
              'kumara krupa - #16/1',
              'Feb 15, 2026',
              s.acidicLowPh,
              Colors.redAccent,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(
    BuildContext context,
    String title,
    String date,
    String status,
    Color statusColor,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.2),
          child: Icon(Icons.eco, color: statusColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(date),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ReportScreen()),
          );
        },
      ),
    );
  }
}
