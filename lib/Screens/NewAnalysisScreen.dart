import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../Services/LanguageProvider.dart';
import '../Widgets/AddressFromLatLong.dart';
import 'ProcessingScreen.dart';
import '../Services/CloudApiService.dart';
import '../Services/SoilImageValidator.dart';

class NewAnalysisScreen extends StatefulWidget {
  const NewAnalysisScreen({super.key});

  @override
  State<NewAnalysisScreen> createState() => _NewAnalysisScreenState();
}

class _NewAnalysisScreenState extends State<NewAnalysisScreen> {
  bool _isFetchingImages = false;
  bool _isUploadingToGCS = false;
  bool _isCheckingQuality = false;

  late CloudApiService apiService;
  bool _apiServiceReady = false;

  List<XFile> selectedImages = [];
  final picker = ImagePicker();

  // Location state (fetched silently in background)
  bool _locationFetched = false;
  bool _isFetchingLocation = false;
  double? _latitude;
  double? _longitude;
  String? _rawAddress;

  // Upload progress
  int _uploadedCount = 0;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/credentials.json').then((json) {
      apiService = CloudApiService(json);
      _apiServiceReady = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = Provider.of<LanguageProvider>(context).strings;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: Text(s.physicalAiAnalysis)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.stepOne,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              s.stepOneInstruction,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),

            // Image Capture Area
            GestureDetector(
              onTap: (_isFetchingImages || _isCheckingQuality) ? null : _showImagePickerOptions,
              child: Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: selectedImages.isNotEmpty
                      ? Colors.green.withOpacity(0.1)
                      : Colors.grey[200],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: selectedImages.isNotEmpty
                        ? Colors.green
                        : Colors.grey[400]!,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
                child: (_isFetchingImages || _isCheckingQuality)
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              _isCheckingQuality
                                  ? Provider.of<LanguageProvider>(context)
                                      .strings
                                      .imageQualityChecking
                                  : '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : selectedImages.isEmpty
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.camera_alt,
                                  color: Colors.grey, size: 64),
                              const SizedBox(height: 8),
                              Text(
                                s.tapToOpenCamera,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 10,
                            ),
                            itemCount: selectedImages.length,
                            itemBuilder: (BuildContext context, int index) {
                              return Center(
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: kIsWeb
                                      ? Image.network(
                                          selectedImages[index].path,
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 200,
                                        )
                                      : Image.file(
                                          File(selectedImages[index].path),
                                          fit: BoxFit.cover,
                                          width: 150,
                                          height: 200,
                                        ),
                                ),
                              );
                            },
                            separatorBuilder:
                                (BuildContext context, int index) {
                              return const SizedBox(width: 10);
                            },
                          ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (selectedImages.isNotEmpty &&
                      !_isUploadingToGCS &&
                      _apiServiceReady)
                  ? _uploadToGCS
                  : null,
              child: _isUploadingToGCS
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _isFetchingLocation
                              ? s.fetchingLocation
                              : '${s.uploadingProgress} $_uploadedCount/${selectedImages.length}...',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : Text(
                      s.runAiAnalysis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }

  // Show options to pick from Gallery or Camera
  void _showImagePickerOptions() {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(s.galleryMultiple),
              onTap: () {
                Navigator.pop(context);
                getImages(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(s.cameraSingle),
              onTap: () {
                Navigator.pop(context);
                getImages(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  // Pick images from gallery or camera and validate quality
  Future getImages(ImageSource source) async {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    setState(() => _isFetchingImages = true);
    try {
      List<XFile> pickedFiles;

      if (source == ImageSource.gallery) {
        pickedFiles = await picker.pickMultiImage(
          imageQuality: 80,
          maxHeight: 1000,
          maxWidth: 1000,
        );
      } else {
        final XFile? pickedFile = await picker.pickImage(
          source: ImageSource.camera,
          imageQuality: 80,
        );
        pickedFiles = pickedFile != null ? [pickedFile] : [];
      }

      if (pickedFiles.isEmpty) return;

      // Validate image quality
      setState(() {
        _isFetchingImages = false;
        _isCheckingQuality = true;
      });

      final validImages = <XFile>[];
      final failedReasons = <String>[];

      for (final file in pickedFiles) {
        final result = await SoilImageValidator.validateFromPath(file.path);

        if (result.isAcceptable) {
          validImages.add(file);
        } else {
          final reasonKey = result.rejectionReason ?? 'imageNotSoil';
          String message;
          switch (reasonKey) {
            case 'imageBlurry':
              message = s.imageBlurry;
              break;
            case 'imageTooDark':
              message = s.imageTooDark;
              break;
            case 'imageTooBright':
              message = s.imageTooBright;
              break;
            default:
              message = s.imageNotSoil;
          }
          failedReasons.add(message);
        }
      }

      if (mounted) {
        setState(() {
          _isCheckingQuality = false;
          if (validImages.isNotEmpty) {
            selectedImages.addAll(validImages);
          }
        });

        // Show rejection dialog for failed images
        if (failedReasons.isNotEmpty) {
          _showRejectionDialog(failedReasons);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${s.errorPickingImages}: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFetchingImages = false;
          _isCheckingQuality = false;
        });
      }
    }
  }

  /// Show dialog listing reasons for rejected images.
  void _showRejectionDialog(List<String> reasons) {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange),
            const SizedBox(width: 8),
            Text(s.imageQualityIssue),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: reasons
              .map((reason) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('• ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Expanded(child: Text(reason)),
                      ],
                    ),
                  ))
              .toList(),
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.retakeImage),
            ),
          ),
        ],
      ),
    );
  }

  /// Fetch location automatically (no user interaction needed)
  Future<void> _autoFetchLocation() async {
    if (_locationFetched) return;

    setState(() => _isFetchingLocation = true);

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) _showLocationDisabledDialog();
        throw 'Location services are disabled.';
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions are denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions are permanently denied.';
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      String address =
          await getAddressFromLatLng(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _rawAddress = address;
          _isFetchingLocation = false;
          _locationFetched = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isFetchingLocation = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Location Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      rethrow;
    }
  }

  void _showLocationDisabledDialog() {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(s.locationServicesDisabled),
        content: Text(s.enableLocationMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(s.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await Geolocator.openLocationSettings();
            },
            child: Text(s.openSettings),
          ),
        ],
      ),
    );
  }

  /// Main upload flow:
  /// 1. Auto-fetch location in background
  /// 2. Upload all images to GCS in parallel (non-blocking async)
  /// 3. Navigate to ProcessingScreen
  void _uploadToGCS() async {
    final s = Provider.of<LanguageProvider>(context, listen: false).strings;

    setState(() {
      _isUploadingToGCS = true;
      _uploadedCount = 0;
    });

    try {
      // Step 1: Auto-fetch location
      await _autoFetchLocation();

      // Step 1b: Require a signed-in user so we can scope the GCS path per user.
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null || uid.isEmpty) {
        throw Exception(s.noSignedInUser);
      }

      // Step 2: Upload all images in parallel using Future.wait
      final uploadFutures = <Future<String?>>[];
      final metadata = <String, String>{
        'lat': '$_latitude',
        'long': '$_longitude',
        if (_rawAddress != null) 'address': _rawAddress!,
      };

      for (int i = 0; i < selectedImages.length; i++) {
        final imageXFile = selectedImages[i];
        final timestamp = DateTime.now().millisecondsSinceEpoch + i;
        final imageName = '$uid/${timestamp}_${i}_${imageXFile.name}';

        uploadFutures.add(
          _uploadSingleImage(imageXFile, imageName, metadata: metadata),
        );
      }

      final results = await Future.wait(uploadFutures);

      // Step 3: Check for failures
      for (int i = 0; i < results.length; i++) {
        if (results[i] == null) {
          throw Exception("Failed to upload image ${i + 1}");
        }
        print('Uploaded image ${i + 1}: ${results[i]}');
      }

      // Step 4: Navigate to ProcessingScreen
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ProcessingScreen(),
          ),
        );
      }
    } catch (e) {
      print("Upload Error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${s.uploadError}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingToGCS = false);
    }
  }

  /// Upload a single image and update progress
  Future<String?> _uploadSingleImage(
    XFile imageXFile,
    String imageName, {
    Map<String, String>? metadata,
  }) async {
    try {
      final Uint8List imageBytes = await imageXFile.readAsBytes();
      final String? downloadLink =
          await apiService.save(imageName, imageBytes, metadata: metadata);

      if (downloadLink != null && mounted) {
        setState(() => _uploadedCount++);
      }

      return downloadLink;
    } catch (e) {
      print("Error uploading $imageName: $e");
      return null;
    }
  }
}
