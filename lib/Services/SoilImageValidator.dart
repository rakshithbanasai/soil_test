import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';

/// Result of an image quality check.
class ImageQualityResult {
  /// True only when ALL checks pass.
  final bool isAcceptable;

  /// ML Kit detected a soil-related label with sufficient confidence.
  final bool isSoilDetected;

  /// Laplacian variance is above the blur threshold.
  final bool isNotBlurry;

  /// Average brightness is within the acceptable range.
  final bool hasGoodLighting;

  /// Key that maps to a localized string in AppStrings. Null when acceptable.
  final String? rejectionReason;

  const ImageQualityResult({
    required this.isAcceptable,
    required this.isSoilDetected,
    required this.isNotBlurry,
    required this.hasGoodLighting,
    this.rejectionReason,
  });
}

/// Validates soil images for quality before upload.
///
/// Checks three dimensions:
/// 1. **Soil detection** — Google ML Kit confirms image contains soil/dirt/earth.
/// 2. **Blur detection** — Laplacian variance on grayscale pixels.
/// 3. **Brightness** — Average luminance within acceptable range.
class SoilImageValidator {
  // --- Tunable thresholds ---
  static const double soilConfidenceThreshold = 0.6;
  static const double blurVarianceThreshold = 100.0;
  static const int brightnessMin = 50;
  static const int brightnessMax = 230;

  /// Labels that indicate the image contains soil.
  static const _soilLabels = {
    'Soil',
    'Dirt',
    'Earth',
    'Ground',
    'Sand',
    'Clay',
    'Mud',
  };

  /// Validates an image given its file path.
  ///
  /// Returns an [ImageQualityResult] describing which checks passed/failed.
  static Future<ImageQualityResult> validateFromPath(String filePath) async {
    final file = File(filePath);
    final imageBytes = await file.readAsBytes();

    final results = await Future.wait([
      _checkIsSoil(filePath),
      _checkBlur(imageBytes),
      _checkBrightness(imageBytes),
    ]);

    final isSoilDetected = results[0];
    final isNotBlurry = results[1];
    final hasGoodLighting = results[2];

    final isAcceptable = isSoilDetected && isNotBlurry && hasGoodLighting;

    return ImageQualityResult(
      isAcceptable: isAcceptable,
      isSoilDetected: isSoilDetected,
      isNotBlurry: isNotBlurry,
      hasGoodLighting: hasGoodLighting,
      rejectionReason: isAcceptable
          ? null
          : _buildRejectionReason(
              isSoilDetected: isSoilDetected,
              isNotBlurry: isNotBlurry,
              hasGoodLighting: hasGoodLighting,
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Soil detection via ML Kit
  // ---------------------------------------------------------------------------

  static Future<bool> _checkIsSoil(String filePath) async {
    final inputImage = InputImage.fromFilePath(filePath);

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(
        confidenceThreshold: soilConfidenceThreshold,
      ),
    );

    try {
      final labels = await labeler.processImage(inputImage);
      for (final label in labels) {
        if (_soilLabels.contains(label.label)) {
          return true;
        }
      }
      return false;
    } finally {
      labeler.close();
    }
  }

  // ---------------------------------------------------------------------------
  // Blur detection via Laplacian variance
  // ---------------------------------------------------------------------------

  static Future<bool> _checkBlur(Uint8List imageBytes) async {
    try {
      final codec = await instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
      if (byteData == null) return false;

      final pixels = byteData.buffer.asUint8List();
      final width = image.width;
      final height = image.height;

      // Convert to grayscale luminance array.
      final gray = List<double>.filled(width * height, 0);
      for (int i = 0; i < width * height; i++) {
        final r = pixels[i * 4];
        final g = pixels[i * 4 + 1];
        final b = pixels[i * 4 + 2];
        gray[i] = 0.299 * r + 0.587 * g + 0.114 * b;
      }

      // Laplacian: 4*center - top - bottom - left - right
      double sum = 0;
      double sumSq = 0;
      int count = 0;

      for (int y = 1; y < height - 1; y++) {
        for (int x = 1; x < width - 1; x++) {
          final idx = y * width + x;
          final laplacian = (4 * gray[idx]) -
              gray[idx - width] -
              gray[idx + width] -
              gray[idx - 1] -
              gray[idx + 1];
          sum += laplacian;
          sumSq += laplacian * laplacian;
          count++;
        }
      }

      final mean = sum / count;
      final variance = (sumSq / count) - (mean * mean);

      image.dispose();

      return variance >= blurVarianceThreshold;
    } catch (e) {
      // If we can't decode, allow the image (don't block on codec errors).
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Brightness check via average luminance
  // ---------------------------------------------------------------------------

  static Future<bool> _checkBrightness(Uint8List imageBytes) async {
    try {
      final codec = await instantiateImageCodec(imageBytes);
      final frame = await codec.getNextFrame();
      final image = frame.image;

      final byteData = await image.toByteData(format: ImageByteFormat.rawRgba);
      if (byteData == null) return false;

      final pixels = byteData.buffer.asUint8List();
      final pixelCount = image.width * image.height;

      double totalLuminance = 0;
      for (int i = 0; i < pixelCount; i++) {
        final r = pixels[i * 4];
        final g = pixels[i * 4 + 1];
        final b = pixels[i * 4 + 2];
        totalLuminance += 0.299 * r + 0.587 * g + 0.114 * b;
      }

      final avgBrightness = totalLuminance / pixelCount;
      image.dispose();

      return avgBrightness >= brightnessMin && avgBrightness <= brightnessMax;
    } catch (e) {
      return true;
    }
  }

  // ---------------------------------------------------------------------------
  // Rejection reason builder
  // ---------------------------------------------------------------------------

  /// Returns a key that maps to a localized string in [AppStrings].
  static String _buildRejectionReason({
    required bool isSoilDetected,
    required bool isNotBlurry,
    required bool hasGoodLighting,
  }) {
    if (!isSoilDetected) return 'imageNotSoil';
    if (!isNotBlurry) return 'imageBlurry';
    if (!hasGoodLighting) return 'imageTooDark';
    return 'imageNotSoil';
  }
}
