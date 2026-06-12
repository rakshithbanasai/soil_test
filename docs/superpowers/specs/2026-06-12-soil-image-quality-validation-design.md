# Soil Image Quality Validation Before GCS Upload

**Date:** 2026-06-12
**Status:** Approved

## Problem

Users can upload any image (blurry, dark, non-soil) to GCS for soil analysis. Bad images lead to unreliable pH, moisture, and nutrient results. We need to validate image quality before upload.

## Approach

**Google ML Kit (Approach A)** — On-device ML image labeling for soil detection, combined with custom Dart-side blur and brightness checks. No internet required, no custom model training needed.

## Architecture

### New Service: `SoilImageValidator`

**File:** `lib/Services/SoilImageValidator.dart`

A single class with one public method:

```dart
static Future<ImageQualityResult> validate(Uint8List imageBytes)
```

Runs three independent checks:

| Check | Method | Technique | Pass Criteria |
|-------|--------|-----------|---------------|
| Soil detection | `_checkIsSoil()` | Google ML Kit Image Labeling | Label "Soil", "Dirt", "Earth", "Ground", or "Sand" with confidence ≥ 0.6 |
| Blur detection | `_checkBlur()` | Laplacian variance on grayscale pixels | Variance ≥ 100 |
| Brightness | `_checkBrightness()` | Average pixel luminance | 50–230 on 0–255 scale |

### Result Model: `ImageQualityResult`

```dart
class ImageQualityResult {
  final bool isAcceptable;
  final bool isSoilDetected;
  final bool isNotBlurry;
  final bool hasGoodLighting;
  final String? rejectionReason; // null if acceptable
}
```

## Data Flow

```
User picks image(s) via camera/gallery
  → Show loading spinner ("Checking image quality...")
  → For each picked image:
      1. Read image bytes from XFile
      2. Run SoilImageValidator.validate(bytes)
      3. Collect results
  → Valid images: add to selectedImages list
  → Failed images: show rejection dialog with specific reason
     - User must retake (no "upload anyway" override)
```

### Multi-image Gallery Picks

- Valid images are added immediately to `selectedImages`
- All failed images are reported in a single dialog listing each rejection
- Only images that pass all three checks are uploaded

### Rejection Dialog

- Title: "Image Quality Issue"
- Body: Specific reason (blurry, too dark, too bright, not soil) with guidance on how to fix
- Single button: "Retake Image" — dismisses dialog, user can pick again

## Rejection Messages (Localized)

| Key | English | Kannada |
|-----|---------|---------|
| `imageBlurry` | Image appears blurry. Hold the camera steady and retake. | ಚಿತ್ರ ಮಸುಕಾಗಿದೆ. ಕ್ಯಾಮೆರಾ ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ತೆಗೆಯಿರಿ. |
| `imageTooDark` | Image is too dark. Move to a well-lit area and retake. | ಚಿತ್ರ ತುಂಬಾ ಕತ್ತಲೆಯಾಗಿದೆ. ಉತ್ತಮ ಬೆಳಕಿನ ಸ್ಥಳಕ್ಕೆ ಹೋಗಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ. |
| `imageTooBright` | Image is overexposed. Avoid direct harsh light and retake. | ಚಿತ್ರ ಅತಿಯಾಗಿ ಪ್ರಕಾಶಮಾನವಾಗಿದೆ. ನೇರ ಬೆಳಕನ್ನು ತಪ್ಪಿಸಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ. |
| `imageNotSoil` | This doesn't appear to be a soil image. Point the camera at the soil surface. | ಇದು ಮಣ್ಣಿನ ಚಿತ್ರವಾಗಿ ಕಂಡುಬಂದಿಲ್ಲ. ಕ್ಯಾಮೆರಾ ಮಣ್ಣಿನ ಮೇಲ್ಮೈಗೆ ಹಿಡಿಯಿರಿ. |
| `imageQualityChecking` | Checking image quality... | ಚಿತ್ರ ಗುಣಮಟ್ಟ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ... |
| `imageQualityIssue` | Image Quality Issue | ಚಿತ್ರ ಗುಣಮಟ್ಟದ ಸಮಸ್ಯೆ |
| `retakeImage` | Retake Image | ಚಿತ್ರ ಮತ್ತೆ ತೆಗೆಯಿರಿ |

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `google_mlkit_image_labeling` | latest | On-device image labeling for soil detection |

No additional packages needed for blur/brightness — uses `dart:typed_data` with raw image bytes from `image_picker`.

ML Kit image labeling uses the built-in base model. No native model download or native config changes required.

## File Changes

| File | Action | Description |
|------|--------|-------------|
| `pubspec.yaml` | Modify | Add `google_mlkit_image_labeling` dependency |
| `lib/Services/SoilImageValidator.dart` | **Create** | Validator class with `validate()` method |
| `lib/Screens/NewAnalysisScreen.dart` | Modify | Add validation in `getImages()` before adding to `selectedImages`; add `_showRejectionDialog()` |
| `lib/Services/LanguageProvider.dart` | Modify | Add 7 new strings to `AppStrings` (EN + KN) |

## Tunable Thresholds

Defined as static constants in `SoilImageValidator`:

- `soilConfidenceThreshold = 0.6`
- `blurVarianceThreshold = 100.0`
- `brightnessMin = 50`
- `brightnessMax = 230`

## What Stays Unchanged

- `CloudApiService.dart` — upload logic unchanged
- `ProcessingScreen.dart` — analysis flow unchanged
- `ReportScreen.dart` — report display unchanged
- Android/iOS native configs — ML Kit works out of the box
