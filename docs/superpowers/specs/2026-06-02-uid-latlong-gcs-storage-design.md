# Per-user GCS storage with lat/long metadata

**Date:** 2026-06-02
**Status:** Approved (awaiting implementation)

## Goal

Change how `NewAnalysisScreen` uploads analysis images to Google Cloud Storage so that each image lives under a per-user folder, and the GPS coordinates for each upload are stored as GCS object metadata instead of being baked into the filename.

## Context

- Bucket: `bai_ph` (project `heartai-caare`), via `lib/Services/CloudApiService.dart`.
- Today, `NewAnalysisScreen._uploadToGCS` builds object names as `{address}_{timestamp}_{file}.jpg`, where `address` is the geocoded string from `getAddressFromLatLng`. The Firebase Auth `uid` is not used.
- `ProfileScreen` already uploads profile photos under `profile_photos/{uid}_{timestamp}.jpg`. Out of scope for this change.
- No Firestore record is written today for analysis uploads.

## Design

### Path shape

- **Before:** `{address}_{timestamp}_{file}.jpg`
- **After:** `{uid}/{timestamp}_{index}_{file}.jpg`

`timestamp` preserves chronological ordering, `index` disambiguates images captured within the same millisecond, and `file` keeps the original filename human-readable when browsing GCS.

### Metadata

GCS object custom metadata will include:

| Key | Value |
| --- | --- |
| `timestamp` | ISO 8601 (existing) |
| `lat` | `position.latitude.toString()` |
| `long` | `position.longitude.toString()` |
| `address` | geocoded address string |

### Code changes

**`lib/Services/CloudApiService.dart`**

- Extend `save` signature to `Future<String?> save(String name, List<int> bytes, {Map<String, String>? metadata})`.
- Always include `timestamp` in the custom metadata (auto-set inside `save`, same as today). Any additional keys passed via `metadata` are added on top. If the caller passes a `timestamp` key, the caller's value wins.
- Pass the merged map into `ObjectMetadata(custom: ...)`.

**`lib/Screens/NewAnalysisScreen.dart`**

- Keep `_autoFetchLocation()` as the source of lat/long and address.
- After the position is resolved, stash `position.latitude`, `position.longitude`, and the raw address string on state (currently only the sanitized `_currentAddress` is kept).
- In `_uploadToGCS`:
  1. Read `FirebaseAuth.instance.currentUser?.uid`. If null, throw an `Exception` with a descriptive message; the existing catch handler surfaces it via SnackBar.
  2. For each image, build the name as `'$uid/$timestamp_$i_${imageXFile.name}'`.
  3. Call `apiService.save(name, bytes, metadata: {'lat': ..., 'long': ..., 'address': ...})`.

### What stays the same

- `ProfileScreen` upload path — unchanged.
- Firestore — no new writes.
- Parallel upload via `Future.wait` and the progress UI — unchanged.
- Navigation to `ProcessingScreen` after success — unchanged.

### Edge cases

- **uid null**: throw early; surfaced via the existing SnackBar error path.
- **Location fetch fails**: existing behavior — rethrow from `_autoFetchLocation`, SnackBar shown, no uploads proceed.
- **Negative lat/long**: irrelevant; values live in metadata, not the filename.

### Testing

Manual verification:

1. Sign in, run a new analysis with at least two images.
2. In the GCS console for bucket `bai_ph`, confirm:
   - Object path is `<uid>/<timestamp>_<index>_<file>.jpg`.
   - Object custom metadata includes `lat`, `long`, `address`, `timestamp`.

There are no automated tests in the project today; none are being added.

## Out of scope

- Writing a Firestore document per analysis image.
- Backfilling or renaming existing objects in `bai_ph`.
- Changing `ProfileScreen` upload paths.
- Updating any downstream report/processing pipeline that may have depended on the old `{address}_...` filename format (none found in `lib/`).
