# Soil Strip Analysis — Capture → Measure → Recommend

- **Status:** Approved (brainstorm complete, pending implementation plan)
- **Date:** 2026-06-14
- **Owner:** product team
- **Related:** `docs/image-quality-validation.md` (existing capture quality gate)

## 1. Overview

Replace the current mock "soil photo → NPK" premise with a **scientifically defensible** end-to-end flow: a farmer photographs a chemical test strip alongside a printed reference card; the app reads N, P, K, and pH on-device; a pure-Dart recommendation engine computes fertilizer product quantities and an application schedule for the chosen crop and acreage; the result is persisted and shown on a real report.

Delivered in **two phases** so the high-value, zero-risk calculator ships first and the risky colorimetry is developed in isolation:

- **Phase 1** — Dosage engine + manual/lab-entry flow. A farmer with existing soil numbers (or a soil-health-card/lab report) enters NPK + pH, picks crop and acreage, and gets a full recommendation. No camera, no computer vision.
- **Phase 2** — Strip capture + on-device colorimetry, wired in as an alternate *input source* for the same engine. The engine does not change.

## 2. Requirements (decisions)

| # | Decision | Choice |
|---|---|---|
| R1 | Parameters measured | N, P, K, pH (4-pad strip) |
| R2 | User | Farmer self-service |
| R3 | Accuracy bar | Directional — "good enough to recommend", not lab-grade |
| R4 | Lighting compensation | Printed reference card framed with the strip |
| R5 | Crop scope | ~10 pan-India field crops: paddy, ragi, maize, sugarcane, cotton, groundnut, wheat, mustard, soybean, pigeon pea |
| R6 | Compute location | On-device (offline-capable) |
| R7 | Delivery | Phased: calculator first (Phase 1), colorimetry second (Phase 2) |

## 3. Non-goals

- Quantitative STCR/target-yield-based recommendations (status-indexed tables only for MVP).
- Plot/farm management as a top-level entity (a test is tied to a user + optional location; multi-plot organization is a follow-up).
- Bespoke offline-first sync beyond Firestore's built-in offline persistence.
- Live weather integration (the irrigation advisory remains a general note for now).
- Soil-photo-based NPK (the existing soil-photo capture is retained only as optional soil-type/color context, not as a measurement).
- Cloud colorimetry / server CV.

## 4. Architecture

**Core principle:** the recommendation engine is a **pure-Dart library with zero Flutter dependencies**. It takes data in, returns a recommendation out, and is fully unit-testable without a device. All UI and platform code wraps around it.

```
PHASE 1                                     PHASE 2
─────────────────────────                   ─────────────────────────────
[New Analysis]                              [New Analysis]
   → choose input: MANUAL                      → choose input: STRIP TEST
   → enter N,P,K,pH                               → capture strip + reference card
   → pick crop + acreage                          → on-device colorimetry → N,P,K,pH
   → ENGINE.compute(...)  ◄── shared ──┐         → pick crop + acreage
   → Recommendation                    │         → ENGINE.compute(...) ◄──┘
   → Report (persisted to Firestore)   │         → Report (persisted)
                                       └─────────┘
```

**App integration:**
- `NewAnalysisScreen` becomes a hub offering **Manual entry** (Phase 1) and **Strip test** (Phase 2). The existing soil-photo capture stays as an optional soil-type/color context step and no longer claims to produce NPK.
- `ReportScreen` reads a real `SoilTest` record instead of hardcoded mock values.
- Dashboard "Recent Reports" reads the same records.
- `ProcessingScreen` runs the engine (and colorimetry, in Phase 2) instead of the fake timed sequence.

**Reused, not rebuilt:** existing geo-location flow (lat/long/address via `geolocator` + `AddressFromLatLong`), existing GCS upload (`CloudApiService`) for the strip photo, existing `SoilImageValidator` (extended with card-presence/framing checks), `AppStrings` localization.

## 5. Phase 1 — Dosage engine

### 5.1 Interface (pure functions)

```
compute(SoilTestInput) → Recommendation

SoilTestInput  = { n, p, k (kg/ha), ph,
                   crop: CropId,
                   area: number,
                   areaUnit: AreaUnit /* acre | hectare | bigha */ }
Recommendation = { statusSummary: { n, p, k /* Low|Medium|High */,
                                    ph /* acidic|neutral|alkaline */ },
                   products: [ { name, totalKg, splits: [ { stage, kg } ] } ],
                   phAdvisory?: { amendment, kg, reason },
                   notes: [],
                   sourceVersion }
```

### 5.2 Algorithm (5 steps — all lookup + arithmetic)

1. **Classify** each nutrient to Low / Medium / High via threshold tables. Defaults are generic-India; per-region overrides later.
2. **Lookup base dose** — crop × (N, P, K status triplet) → recommended N, P₂O₅, K₂O in kg/ha.
3. **Convert nutrients → products.** DAP supplies *both* P₂O₅ and N, so N from DAP must be credited before computing urea:
   ```
   dapKg   = P2O5 / 0.46                 // DAP is 46% P₂O₅, 18% N
   nFromDap = dapKg × 0.18
   mopKg   = K2O  / 0.60                 // MOP is 60% K₂O
   ureaKg  = max(0, N − nFromDap) / 0.46 // Urea is 46% N
   ```
4. **Split schedule** per crop (e.g. paddy: urea 50% basal / 25% tillering / 25% panicle-initiation; DAP & MOP 100% basal).
5. **Scale by area** (every kg × area-in-ha; present in kg) and emit a **pH advisory** (acidic → lime; sodic/alkaline → gypsum), kept separate from the NPK dosage.

### 5.3 Data the engine depends on (plain Dart const tables, no network)

- `cropRecommendationTable` — 10 crops × status combos → N, P₂O₅, K₂O (kg/ha)
- `statusThresholds` — per-nutrient L/M/H cutoffs
- `productNutrientContent` — Urea (46% N), DAP (18% N / 46% P₂O₅), MOP (60% K₂O)
- `splitSchedule` — per-crop stage percentages

### 5.4 ⚠️ Data-sourcing requirement (non-negotiable)

Fertilizer dosage is consequential — wrong amounts cost yield, money, and soil health. The *code* is correct by construction; **the numbers in the tables are the liability.** Every recommendation row must be sourced from **ICAR / state agriculture university** booklets and reviewed by an agronomist, and each row carries a `sourceVersion` so outputs are traceable. This spec ships the table **structure** only; authoritative population happens during implementation. No recommendation may ship with unsourced numbers.

## 6. Phase 2 — Strip capture & colorimetry

Favors robustness over cleverness: guided placement + a physical reference beat fragile CV for a self-service farmer.

### 6.0 Kit dependency (Phase-2 prerequisite)

Commit to **one specific strip kit** (partner or design our own) providing: a strip with a known pad layout, a printed reference card, and reproducible chemistry. We then **pre-calibrate** its color chart once (6.3) and ship that data in the app. Without a defined kit, colorimetry is guesswork and Phase 2 does not proceed.

### 6.1 Capture screen (guided framing)

Camera overlay shows two slots — "place strip here" and "place card here" — with a lighting hint (avoid shadow / direct glare). On capture, reuse/extend `SoilImageValidator` (blur, brightness) **plus** a card-presence check.

### 6.2 Colorimetry pipeline (on-device Dart, same `dart:ui` pixel access as the validator)

```
capture → locate reference card (known patch positions via guided slot)
        → per-channel color correction (white-point & black-point → affine gain)
        → apply correction to strip-pad regions
        → per pad: average corrected RGB → match against calibrated chart → value
```

- **Localization = guided geometry, not detection.** Placement is templated and the card acts as a fiducial; pads fall at known coordinates after an auto-crop to the card corners. We never try to "find" pads in the wild.
- **Correction = per-channel affine** (white- and black-point from the card's neutral patches). Good enough for directional accuracy; a full 3×3 matrix is a later enhancement, not MVP.
- **Color → value** = nearest calibrated chart color (RGB, optionally Lab), with linear interpolation between the two nearest neighbors. Each pad's chart maps to its concentration/pH.

### 6.3 Calibration (one-time, by us, per kit SKU)

For each pad, prepare solutions at the chart's stated concentrations, photograph under reference lighting with the card, extract the corrected RGB, and store `{ referenceRGB → value }` as the chart. Shipped as Dart data; users never calibrate.

### 6.4 Confidence & fallback

Distance to the nearest chart color yields a confidence score. Below threshold the app says "couldn't read clearly" and offers **retake or manual entry**. It never silently emits a possibly-wrong number that drives a dosage.

## 7. Data model & persistence

### 7.1 Firestore document — `soil_tests/{testId}`

```
{
  uid, createdAt (serverTimestamp),
  source: 'manual' | 'strip',
  location?: { lat, long, address },      // reuse existing geo flow
  input: { measured: { n, p, k, ph, unit },
           status: { n, p, k, ph },
           crop, area, areaUnit },
  recommendation: { statusSummary,
                    products: [ { name, totalKg, splits: [ { stage, kg } ] } ],
                    phAdvisory?, notes[], sourceVersion },
  images?: [ gcsUrls ],                    // strip photo (Phase 2)
  confidence?: number                      // strip only
}
```

### 7.2 Read/write paths

- **Write:** NewAnalysis → `engine.compute()` → write one `soil_tests` doc → open `ReportScreen(testId)`.
- **ReportScreen:** load by `testId`, render `recommendation`.
- **Dashboard "Recent Reports":** `soil_tests` where `uid == currentUser`, `orderBy createdAt desc`, limit N.
- **ProcessingScreen:** runs the real engine / colorimetry, then navigates on completion.

### 7.3 Offline

The engine runs fully on-device — no network for the math. The only network need is the Firestore write, and `cloud_firestore` enables **offline persistence by default on mobile**, so the write queues locally and syncs when connectivity returns; the report renders immediately from local cache. No bespoke offline-first work for MVP — confirm persistence stays enabled.

### 7.4 Security rule

A user may create only docs tagged with their own uid, and read/update/delete only their own:

```
match /soil_tests/{testId} {
  allow create: if request.auth != null
                && request.resource.data.uid == request.auth.uid;
  allow read, update, delete: if request.auth != null
                              && resource.data.uid == request.auth.uid;
}
```

### 7.5 File layout

```
lib/Engine/dosage_engine.dart        // pure compute() + types
lib/Engine/data/{crops,thresholds,products,splits}.dart
lib/Models/soil_test.dart            // SoilTestInput, Recommendation, Firestore mapping
lib/Services/strip_colorimeter.dart  // Phase 2
lib/Screens/...                      // reworked NewAnalysisScreen, ReportScreen
```

### 7.6 Localization

New `AppStrings` keys for crop names, product names (Urea/DAP/MOP), stage names, status labels, advisories, capture instructions, and confidence messages — including Kannada translations.

## 8. Error handling

Guiding rule: **fail closed and explain — never fabricate a number that drives a dosage.** Every failure surfaces a localized, actionable message.

| Failure | Handling |
|---|---|
| Capture quality (blur / dark / bright / card-or-strip out of slot) | Reuse `SoilImageValidator` + framing check → specific localized retake prompt |
| Colorimetry low confidence | "Couldn't read clearly" → retake or manual entry; no silent value |
| Alignment failure (card fiducials not found) | Ask to realign strip + card and retake |
| Out-of-range value (pH/N beyond chart span) | Clamp to chart min/max + "very high/low — confirm with a lab"; never extrapolate |
| Invalid manual input (empty/negative, area ≤ 0, pH outside 0–14) | Form validation blocks `compute()` |
| No signed-in user at save time | Persist requires a uid (matches existing upload flow) → prompt login; result still shown |
| Network failure at Firestore write | Offline cache queues it; UI shows "saved locally, will sync"; report renders from local data immediately |
| Image upload failure (Phase 2) | Non-fatal — test saves with recommendation; image is optional |
| Missing crop/status table row | Fail closed: "data unavailable for this crop/condition" instead of inventing a dose |
| Engine guardrails | Negative urea weight clamped to 0 via `max(0, …)` |
| Missing Kannada key | Falls back to English (provider already defaults to English) |

**Mandatory UI disclaimer on every recommendation:** *"Based on standard recommendations; confirm with your local agriculture officer"* — plus the visible `sourceVersion`.

## 9. Testing

The pure-engine design makes the riskiest math the easiest to test.

**Engine unit tests (highest priority — pure functions, no device):**
- Status classification at each L/M/H threshold boundary
- Nutrient→product math — the critical suite:
  - DAP's N contribution subtracted before urea is computed
  - Zero-P case → no DAP, all N from urea
  - Zero-N case → urea = 0, no negative weights
  - MOP quantity correct for K₂O
- Splits sum to 100% per crop; stage weights correct
- Area scaling, pH advisory routing, out-of-range clamping, fail-closed on a missing table row

**Table-integrity tests (catches data gaps, not logic):**
- every crop × status triplet has a row (no holes)
- every row carries a `sourceVersion`
- product percentages and split percentages are consistent

**Colorimetry tests (Phase 2):**
- Color-correction function — synthetic image with known card colors under a simulated illuminant → corrected output matches reference within tolerance
- Chart mapping — corrected pad RGB → expected value (nearest + interpolation); confidence thresholding
- Golden fixtures — a small set of real strip+card photos with known expected values as regression images

**Widget tests** (existing `test/` dir, `flutter_test` already a dev dep):
- NewAnalysis manual-entry form rejects invalid input
- ReportScreen renders from a `SoilTest` fixture
- ProcessingScreen transitions on completion

**Field validation (in the plan, not the code):** a real strip-vs-lab comparison run before any accuracy claim ships — this is how we honor the "directional, not lab-grade" promise honestly.

## 10. Phasing / delivery

- **Phase 1 (first implementation plan):** engine + manual-entry flow + persisted report + reworked ReportScreen/ProcessingScreen/Dashboard reads. Ships standalone value.
- **Phase 2 (follow-up plan):** kit selection + calibration data + capture screen + colorimetry, wired as an alternate input.

## 11. Dependencies & open items

- **D1 — Authoritative agronomy tables** (ICAR/SAU) for all 10 crops × status combos, thresholds, and splits. Blocks shipping any recommendation with real numbers.
- **D2 — Strip kit** selected/defined (Phase 2 prerequisite): pad geometry, reference card, chemistry.
- **D3 — Calibration dataset** for the chosen kit (Phase 2): reference RGB → value per pad.
- **D4 — Agronomist review** of the disclaimer language and the fail-closed messaging.
