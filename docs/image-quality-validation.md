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
Each image is validated via SoilImageValidator.validateFromPath()
  ↓
┌─ ALL pass → Image added to upload queue
└─ ANY fails → Rejection dialog with specific reason
```

For multi-image gallery picks: valid images are added immediately, only failed ones are reported in a single dialog.

## Architecture

### SoilImageValidator (`lib/Services/SoilImageValidator.dart`)

Static service class — no initialization needed. Single entry point:

```dart
static Future<ImageQualityResult> validateFromPath(String filePath)
```

Uses `InputImage.fromFilePath()` for ML Kit (handles format detection automatically) and `instantiateImageCodec` for pixel-level blur/brightness analysis.

### ImageQualityResult

Immutable model with the following fields:
- `isAcceptable` — true only when all checks pass
- `isSoilDetected`, `isNotBlurry`, `hasGoodLighting` — individual check results
- `rejectionReason` — string key (`'imageBlurry'`, `'imageTooDark'`, `'imageTooBright'`, `'imageNotSoil'`) mapping to localized strings in `LanguageProvider`

## Thresholds

| Parameter | Default | Effect |
|-----------|---------|--------|
| `soilConfidenceThreshold` | 0.6 | Lower = more permissive (accepts less certain soil images) |
| `blurVarianceThreshold` | 100.0 | Lower = more permissive (accepts blurrier images) |
| `brightnessMin` | 50 | Lower = accepts darker images |
| `brightnessMax` | 230 | Higher = accepts brighter images |

These are static constants in `SoilImageValidator` and can be tuned without changing the rest of the code.

## User Experience

1. **On selection:** A spinner appears with "Checking image quality..." text
2. **If rejected:** A modal dialog lists every failed image with its specific reason. The user must dismiss and retake.
3. **If partially valid** (multi-image gallery pick): Valid images are added; only failed ones are reported.
4. **Localization:** All rejection messages are available in English and Kannada.

## Dependencies

- `google_mlkit_image_labeling: ^0.13.0` — on-device image labeling (no internet required)
- `google_mlkit_commons` — transitive dependency providing `InputImage` APIs

## Files

| File | Purpose |
|------|---------|
| `lib/Services/SoilImageValidator.dart` | Validation logic (soil detection, blur, brightness) |
| `lib/Screens/NewAnalysisScreen.dart` | Integration into image capture flow |
| `lib/Services/LanguageProvider.dart` | Localized rejection messages (EN + KN) |

## Limitations

- ML Kit's image labeling is generic (not soil-specific). It may occasionally pass non-soil images that share visual similarity (e.g., sand-colored surfaces).
- Blur detection uses a fixed Laplacian threshold — some marginal images may be incorrectly accepted or rejected.
- Kannada translations should be reviewed by a native speaker.

## Approach Strategy

The validation strategy prioritizes **blocking bad data at the source** over convenience:

1. **Fail early, fail clear** — Images are validated immediately on selection, not at upload time. The user gets instant feedback on what went wrong and how to fix it.

2. **No override** — There is no "Upload Anyway" button. If the validation says the image is bad, the user must retake. This prevents low-quality data from entering the analysis pipeline.

3. **Three independent checks** — Soil detection, blur, and brightness are decoupled. Each can be tuned independently via thresholds without affecting the others.

4. **On-device only** — All checks run locally using Google ML Kit's built-in model. No network calls, no latency, no privacy concerns. Works offline.

5. **Graceful degradation** — If the image codec fails to decode (corrupt file), blur and brightness checks return `true` (allow). We block on what we can verify, not on what we can't.

6. **Extensible** — The `SoilImageValidator` class is designed to be easily extended. Additional checks (e.g., minimum resolution, aspect ratio) can be added as new methods and composed into the `validateFromPath()` flow.
