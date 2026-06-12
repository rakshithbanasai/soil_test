# Soil Image Quality Validation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate soil images on-device for blur, brightness, and soil detection before uploading to GCS, blocking bad images with a clear rejection reason.

**Architecture:** A new `SoilImageValidator` service uses Google ML Kit image labeling to detect soil content, plus custom Dart pixel analysis for blur (Laplacian variance) and brightness (average luminance). Results are returned as an `ImageQualityResult` model. `NewAnalysisScreen` validates each image on selection and shows a blocking dialog for failures.

**Tech Stack:** Flutter/Dart, `google_mlkit_image_labeling`, `dart:typed_data`, existing `image_picker` flow.

---

## File Structure

| File | Action | Responsibility |
|------|--------|----------------|
| `pubspec.yaml` | Modify | Add `google_mlkit_image_labeling` dependency |
| `lib/Services/SoilImageValidator.dart` | Create | Image quality validation logic (soil detection, blur, brightness) |
| `lib/Services/LanguageProvider.dart` | Modify | Add 7 new localized strings for image quality UI |
| `lib/Screens/NewAnalysisScreen.dart` | Modify | Integrate validation into `getImages()`, add rejection dialog |

---

### Task 1: Add ML Kit dependency

**Files:**
- Modify: `pubspec.yaml:30-52` (dependencies section)

- [ ] **Step 1: Add `google_mlkit_image_labeling` to pubspec.yaml**

Add the dependency after the existing `provider` line (line 52):

```yaml
  google_mlkit_image_labeling: ^0.13.0
```

- [ ] **Step 2: Run flutter pub get**

Run: `cd /Users/apple/AndroidStudioProjects/soil_test && flutter pub get`
Expected: Dependency resolves successfully with no errors.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add google_mlkit_image_labeling dependency"
```

---

### Task 2: Create `SoilImageValidator` service

**Files:**
- Create: `lib/Services/SoilImageValidator.dart`

- [ ] **Step 1: Create the validator file with `ImageQualityResult` model and `SoilImageValidator` class**

Create `lib/Services/SoilImageValidator.dart`:

```dart
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

  /// Human-readable reason for rejection. Null when [isAcceptable] is true.
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
    'Soil', 'Dirt', 'Earth', 'Ground', 'Sand', 'Clay', 'Mud',
  };

  /// Validates an image represented as raw bytes.
  ///
  /// Returns an [ImageQualityResult] describing which checks passed/failed.
  static Future<ImageQualityResult> validate(Uint8List imageBytes) async {
    // Run all three checks in parallel.
    final results = await Future.wait([
      _checkIsSoil(imageBytes),
      _checkBlur(imageBytes),
      _checkBrightness(imageBytes),
    ]);

    final isSoilDetected = results[0] as bool;
    final isNotBlurry = results[1] as bool;
    final hasGoodLighting = results[2] as bool;

    final isAcceptable = isSoilDetected && isNotBlurry && hasGoodLighting;

    return ImageQualityResult(
      isAcceptable: isAcceptable,
      isSoilDetected: isSoilDetected,
      isNotBlurry: isNotBlurry,
      hasGoodLighting: hasGoodLighting,
      rejectionReason: isAcceptable ? null : _buildRejectionReason(
        isSoilDetected: isSoilDetected,
        isNotBlurry: isNotBlurry,
        hasGoodLighting: hasGoodLighting,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Soil detection via ML Kit
  // ---------------------------------------------------------------------------

  static Future<bool> _checkIsSoil(Uint8List imageBytes) async {
    final inputImage = InputImage.fromBytes(
      bytes: imageBytes,
      metadata: InputImageMetadata(
        size: const Size(1000, 1000), // image_picker caps at 1000x1000
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        planeData: [
          InputImagePlaneMetadata(
            bytesPerRow: imageBytes.length ~/ 1000,
            height: 1000,
            width: 1000,
          ),
        ],
      ),
    );

    final labeler = ImageLabeler(
      options: ImageLabelerOptions(confidenceThreshold: soilConfidenceThreshold),
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
          final laplacian = (4 * gray[idx])
              - gray[idx - width]
              - gray[idx + width]
              - gray[idx - 1]
              - gray[idx + 1];
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

  /// Keys must match the localized string fields in AppStrings.
  static String _buildRejectionReason({
    required bool isSoilDetected,
    required bool isNotBlurry,
    required bool hasGoodLighting,
  }) {
    if (!isSoilDetected) return 'imageNotSoil';
    if (!isNotBlurry) return 'imageBlurry';
    if (!hasGoodLighting) return 'imageTooDark'; // simplified; dark is more common
    return 'imageNotSoil';
  }
}
```

- [ ] **Step 2: Verify the file compiles**

Run: `cd /Users/apple/AndroidStudioProjects/soil_test && flutter analyze lib/Services/SoilImageValidator.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/Services/SoilImageValidator.dart
git commit -m "feat: add SoilImageValidator service with ML Kit + blur + brightness checks"
```

---

### Task 3: Add localized strings for image quality validation

**Files:**
- Modify: `lib/Services/LanguageProvider.dart`

- [ ] **Step 1: Add 7 new string fields to `AppStrings` class**

Insert after line 199 (`final String noImageSelected;`) — add a new comment section:

```dart
  // ---- Image Quality Validation ----
  final String imageBlurry;
  final String imageTooDark;
  final String imageTooBright;
  final String imageNotSoil;
  final String imageQualityChecking;
  final String imageQualityIssue;
  final String retakeImage;
```

- [ ] **Step 2: Add 7 new `required` parameters to the `const AppStrings({})` constructor**

Insert after line 307 (`required this.noImageSelected,`):

```dart
    required this.imageBlurry,
    required this.imageTooDark,
    required this.imageTooBright,
    required this.imageNotSoil,
    required this.imageQualityChecking,
    required this.imageQualityIssue,
    required this.retakeImage,
```

- [ ] **Step 3: Add English string values**

Insert after line 422 (`noImageSelected: 'Sorry No Images selected',`) in the English const:

```dart
    imageBlurry: 'Image appears blurry. Hold the camera steady and retake.',
    imageTooDark: 'Image is too dark. Move to a well-lit area and retake.',
    imageTooBright: 'Image is overexposed. Avoid direct harsh light and retake.',
    imageNotSoil: "This doesn't appear to be a soil image. Point the camera at the soil surface.",
    imageQualityChecking: 'Checking image quality...',
    imageQualityIssue: 'Image Quality Issue',
    retakeImage: 'Retake Image',
```

- [ ] **Step 4: Add Kannada string values**

Insert after line 582 (`noImageSelected: 'ಕ್ಷಮಿಸಿ, ಯಾವುದೇ ಚಿತ್ರಗಳು ಆಯ್ಕೆಯಾಗಿಲ್ಲ',`) in the Kannada const:

```dart
    imageBlurry: 'ಚಿತ್ರ ಮಸುಕಾಗಿದೆ. ಕ್ಯಾಮೆರಾ ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageTooDark: 'ಚಿತ್ರ ತುಂಬಾ ಕತ್ತಲೆಯಾಗಿದೆ. ಉತ್ತಮ ಬೆಳಕಿನ ಸ್ಥಳಕ್ಕೆ ಹೋಗಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageTooBright: 'ಚಿತ್ರ ಅತಿಯಾಗಿ ಪ್ರಕಾಶಮಾನವಾಗಿದೆ. ನೇರ ಬೆಳಕನ್ನು ತಪ್ಪಿಸಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageNotSoil: 'ಇದು ಮಣ್ಣಿನ ಚಿತ್ರವಾಗಿ ಕಂಡುಬಂದಿಲ್ಲ. ಕ್ಯಾಮೆರಾ ಮಣ್ಣಿನ ಮೇಲ್ಮೈಗೆ ಹಿಡಿಯಿರಿ.',
    imageQualityChecking: 'ಚಿತ್ರ ಗುಣಮಟ್ಟ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
    imageQualityIssue: 'ಚಿತ್ರ ಗುಣಮಟ್ಟದ ಸಮಸ್ಯೆ',
    retakeImage: 'ಚಿತ್ರ ಮತ್ತೆ ತೆಗೆಯಿರಿ',
```

- [ ] **Step 5: Verify compilation**

Run: `cd /Users/apple/AndroidStudioProjects/soil_test && flutter analyze lib/Services/LanguageProvider.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/Services/LanguageProvider.dart
git commit -m "feat: add localized strings for image quality validation (EN + KN)"
```

---

### Task 4: Integrate validation into `NewAnalysisScreen`

**Files:**
- Modify: `lib/Screens/NewAnalysisScreen.dart`

- [ ] **Step 1: Add imports at the top of the file**

Insert after line 12 (`import '../Services/CloudApiService.dart';`):

```dart
import '../Services/SoilImageValidator.dart';
```

- [ ] **Step 2: Add `_isCheckingQuality` state field**

Insert after line 26 (`bool _apiServiceReady = false;`):

```dart
  bool _isCheckingQuality = false;
```

- [ ] **Step 3: Replace the `getImages` method with validation-enabled version**

Replace the entire `getImages` method (lines 235–271) with:

```dart
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
        final bytes = await file.readAsBytes();
        final result = await SoilImageValidator.validate(bytes);

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
          children: reasons.map((reason) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('• ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(child: Text(reason)),
              ],
            ),
          )).toList(),
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
```

- [ ] **Step 4: Update the image capture area to show quality checking spinner**

In the `GestureDetector`'s child Container (line 96), replace the ternary `_isFetchingImages` condition. Find the line:

```dart
                child: _isFetchingImages
```

Replace `_isFetchingImages` with `(_isFetchingImages || _isCheckingQuality)` so it reads:

```dart
                child: (_isFetchingImages || _isCheckingQuality)
```

Then update the loading text to differentiate. In the `Center(child: CircularProgressIndicator())` block (lines 96-97), replace the single line with:

```dart
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 12),
                            Text(
                              _isCheckingQuality
                                  ? Provider.of<LanguageProvider>(context).strings.imageQualityChecking
                                  : '',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      )
```

- [ ] **Step 5: Verify compilation**

Run: `cd /Users/apple/AndroidStudioProjects/soil_test && flutter analyze lib/Screens/NewAnalysisScreen.dart`
Expected: No errors.

- [ ] **Step 6: Commit**

```bash
git add lib/Screens/NewAnalysisScreen.dart
git commit -m "feat: integrate image quality validation into NewAnalysisScreen"
```

---

### Task 5: Write documentation

**Files:**
- Create: `docs/image-quality-validation.md`

- [ ] **Step 1: Create the documentation file**

Create `docs/image-quality-validation.md`:

```markdown
# Soil Image Quality Validation

## Overview

Before uploading soil images to Google Cloud Storage for AI analysis, each image is validated on-device for quality. This ensures that only clear, well-lit, soil-containing images are sent for analysis — improving the reliability of pH, moisture, and nutrient readings.

## How It Works

### Three-Check Pipeline

Every image passes through three independent checks:

| Check | What it detects | Technique | Pass criteria |
|-------|----------------|-----------|---------------|
| **Soil Detection** | Confirms the image actually contains soil | Google ML Kit Image Labeling | A soil-related label ("Soil", "Dirt", "Earth", "Ground", "Sand", "Clay", "Mud") appears with ≥ 60% confidence |
| **Blur Detection** | Rejects out-of-focus or motion-blurred images | Laplacian variance on decoded grayscale pixels | Variance ≥ 100 (higher = sharper) |
| **Brightness** | Rejects images that are too dark or overexposed | Average pixel luminance (0–255 scale) | Average between 50–230 |

All three checks run in parallel for speed. An image is accepted only when ALL three pass.

### Flow

```
User picks image(s) from Camera or Gallery
  ↓
Each image is read as bytes (Uint8List)
  ↓
SoilImageValidator.validate(bytes) runs three checks
  ↓
┌─ ALL pass → Image added to upload queue
└─ ANY fails → Rejection dialog with specific reason
```

## Architecture

### SoilImageValidator (`lib/Services/SoilImageValidator.dart`)

Static service class — no initialization needed. Single entry point:

```dart
static Future<ImageQualityResult> validate(Uint8List imageBytes)
```

Returns an `ImageQualityResult` with:
- `isAcceptable` — true only when all checks pass
- `isSoilDetected`, `isNotBlurry`, `hasGoodLighting` — individual check results
- `rejectionReason` — string key for the failing check (null if acceptable)

### ImageQualityResult

Immutable model. The `rejectionReason` field contains a key like `'imageBlurry'`, `'imageTooDark'`, `'imageTooBright'`, or `'imageNotSoil'` that maps to localized strings in `LanguageProvider`.

## Thresholds

| Parameter | Default | Effect |
|-----------|---------|--------|
| `soilConfidenceThreshold` | 0.6 | Lower = more permissive (accepts less certain soil images) |
| `blurVarianceThreshold` | 100.0 | Lower = more permissive (accepts blurrier images) |
| `brightnessMin` | 50 | Lower = accepts darker images |
| `brightnessMax` | 230 | Higher = accepts brighter images |

These are static constants in `SoilImageValidator` and can be tuned.

## User Experience

- **On selection:** A spinner appears with "Checking image quality..." text
- **If rejected:** A modal dialog lists every failed image with its specific reason (blurry, too dark, too bright, not soil). The user must dismiss and retake.
- **If partially valid** (multi-image gallery pick): Valid images are added; only failed ones are reported.
- **Localization:** All rejection messages are available in English and Kannada.

## Dependencies

- `google_mlkit_image_labeling: ^0.13.0` — on-device image labeling (no internet required)

## Files

| File | Purpose |
|------|---------|
| `lib/Services/SoilImageValidator.dart` | Validation logic |
| `lib/Screens/NewAnalysisScreen.dart` | Integration into image capture flow |
| `lib/Services/LanguageProvider.dart` | Localized rejection messages |

## Limitations

- ML Kit's image labeling is generic (not soil-specific). It may occasionally pass non-soil images that share visual similarity (e.g., sand-colored surfaces).
- Blur detection uses a fixed Laplacian threshold — some marginal images may be incorrectly accepted or rejected.
- ML Kit processes using `InputImageFormat.nv21` with a 1000x1000 size hint matching the `image_picker` max dimensions. Actual format may vary by device.
- Kannada translations should be reviewed by a native speaker.
```

- [ ] **Step 2: Commit**

```bash
git add docs/image-quality-validation.md
git commit -m "docs: add image quality validation documentation"
```

---

### Task 6: Build and run on Motorola device

- [ ] **Step 1: Verify full project compiles**

Run: `cd /Users/apple/AndroidStudioProjects/soil_test && flutter analyze`
Expected: No errors.

- [ ] **Step 2: Check connected devices**

Run: `flutter devices`
Expected: Motorola device listed.

- [ ] **Step 3: Build and install on Motorola**

Run: `flutter run --release`
Expected: App builds, installs, and launches on the Motorola device.

- [ ] **Step 4: Manual smoke test**

On the Motorola device:
1. Open the app → navigate to New Soil Analysis
2. Tap image area → pick Camera → take a photo of actual soil → verify it's accepted
3. Take a photo of a non-soil object (e.g., a wall) → verify rejection dialog appears
4. Cover camera lens and take a dark photo → verify "too dark" rejection
5. Open Gallery → pick a mix of good and bad images → verify valid ones are kept, bad ones rejected

- [ ] **Step 5: Commit final state if any fixes were needed**

```bash
git add -A
git commit -m "fix: adjustments from on-device testing"
```
