import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:soil_test/Services/CloudApiService.dart';
import 'package:soil_test/Services/LanguageProvider.dart';
import 'package:soil_test/Utils/app_colors.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  late CloudApiService _apiService;
  bool _apiServiceReady = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/credentials.json').then((json) {
      _apiService = CloudApiService(json);
      setState(() => _apiServiceReady = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageProvider>(context).strings;

    return Scaffold(
      appBar: AppBar(title: Text(s.myProfile)),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Determine profile data: use Firestore if available, fall back to Firebase Auth
          Map<String, dynamic> userData;
          bool hasFirestoreData = snapshot.hasData && snapshot.data!.exists;

          if (hasFirestoreData) {
            userData = snapshot.data!.data() as Map<String, dynamic>;
          } else {
            // Fallback: build profile from Firebase Auth user
            final authUser = user;
            final parts = (authUser?.displayName ?? '').split(' ');
            userData = {
              'firstName': parts.isNotEmpty ? parts.first : '',
              'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
              'email': authUser?.email ?? '',
              'phoneNumber': authUser?.phoneNumber ?? '',
              'photoUrl': authUser?.photoURL ?? '',
            };

            // Try to create the Firestore document in the background
            _ensureUserDocument();
          }

          String? photoUrl = userData['photoUrl'] as String?;

          return Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                // Profile Photo
                GestureDetector(
                  onTap: _apiServiceReady ? _pickAndUploadPhoto : null,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: app_colors.primaryColor,
                        backgroundImage:
                            (photoUrl != null && photoUrl.isNotEmpty)
                                ? NetworkImage(photoUrl)
                                : null,
                        child: (photoUrl == null || photoUrl.isEmpty)
                            ? const Icon(Icons.person,
                                size: 60, color: Colors.white)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: app_colors.primaryColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.white, width: 2),
                          ),
                          child: _isUploadingPhoto
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt,
                                  color: Colors.white, size: 16),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  s.tapToChangePhoto,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                ),
                const SizedBox(height: 30),
                _infoTile(s.name,
                    "${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}"),
                _infoTile(s.email, userData['email'] ?? 'N/A'),
                _infoTile(s.phone, userData['phoneNumber'] ?? 'N/A'),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.pop(context);
                    },
                    child: Text(s.logout,
                        style: const TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Try to create Firestore user document if it doesn't exist (non-blocking)
  Future<void> _ensureUserDocument() async {
    if (user == null) return;
    try {
      final doc = FirebaseFirestore.instance.collection('users').doc(user!.uid);
      final snapshot = await doc.get();
      if (!snapshot.exists) {
        final parts = (user!.displayName ?? '').split(' ');
        await doc.set({
          'uid': user!.uid,
          'firstName': parts.isNotEmpty ? parts.first : '',
          'lastName': parts.length > 1 ? parts.sublist(1).join(' ') : '',
          'email': user!.email ?? '',
          'phoneNumber': user!.phoneNumber ?? '',
          'photoUrl': user!.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) setState(() {}); // Refresh to show Firestore data
      }
    } catch (e) {
      debugPrint('Firestore document creation skipped: $e');
    }
  }

  /// Pick a profile photo and upload to GCS
  Future<void> _pickAndUploadPhoto() async {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (pickedFile == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final Uint8List imageBytes = await pickedFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final imageName = 'profile_photos/${user?.uid}_$timestamp.jpg';

      final String? downloadUrl =
          await _apiService.save(imageName, imageBytes);

      if (downloadUrl != null) {
        // Save the URL to Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user?.uid)
            .update({'photoUrl': downloadUrl});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.profilePhotoUpdated),
              backgroundColor: Colors.green,
            ),
          );
          // Trigger rebuild to show new photo
          setState(() {});
        }
      } else {
        throw Exception("Upload failed");
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${s.errorUpdatingPhoto}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Widget _infoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.grey)),
          Flexible(
            child: Text(value,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
