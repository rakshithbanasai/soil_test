# Localization (i18n) — Banas AI Soil Test App

This document describes the internationalization (i18n) system implemented in the Banas AI Flutter application.

## Supported Languages

| Code | Language  |
|------|-----------|
| `en` | English   |
| `kn` | ಕನ್ನಡ (Kannada) |

---

## Architecture Overview

```
lib/
├── Services/
│   └── LanguageProvider.dart    ← Core: state management + all translations
├── Screens/
│   └── LanguageSelectionScreen.dart  ← UI for picking a language
├── main.dart                    ← Provider wrapping
└── Screens/*.dart               ← Consume strings via Provider
```

### How It Works

1. **`LanguageProvider`** (`lib/Services/LanguageProvider.dart`)
   - Extends `ChangeNotifier` (from the `provider` package).
   - Persists the selected language code (`'en'` or `'kn'`) to **SharedPreferences** under the key `app_language`.
   - Exposes a `strings` getter that returns an `AppStrings` instance matching the current language.
   - Initialized in `main.dart` before `runApp()`.

2. **`AppStrings`** — a plain Dart class with a field per UI string.
   - Two `static const` instances: `AppStrings.english` and `AppStrings.kannada`.
   - Every user-visible string in the app is defined here.

3. **Screens** — consume strings via `Provider.of<LanguageProvider>(context).strings`.

4. **`LanguageSelectionScreen`** — a dedicated screen with radio-style language pickers, shown on first launch or accessible from the dashboard language chip.

---

## Adding a New Language

To add a new language (e.g., Hindi — `hi`):

### 1. Add the language code constant

```dart
// In LanguageProvider.dart
class LanguageCode {
  static const String english = 'en';
  static const String kannada = 'kn';
  static const String hindi = 'hi';       // ← NEW
}
```

### 2. Create a new `AppStrings` constant

```dart
// In LanguageProvider.dart, inside AppStrings class
static const AppStrings hindi = AppStrings(
  title: 'Banas AI',
  welcomeBack: 'वापसी पर स्वागत है,',
  soilAnalysis: 'नई मिट्टी विश्लेषण',
  // ... translate every field
);
```

### 3. Register in the lookup map

```dart
static final Map<String, AppStrings> _localizedStrings = {
  LanguageCode.english: AppStrings.english,
  LanguageCode.kannada: AppStrings.kannada,
  LanguageCode.hindi: AppStrings.hindi,    // ← NEW
};
```

### 4. Add a new option in `LanguageSelectionScreen`

```dart
_languageOption(
  code: LanguageCode.hindi,
  label: 'हिन्दी',
  subtitle: 'हिन्दी में जारी रखें',
  flag: '🇮🇳',
),
```

---

## Usage in Screens

```dart
import 'package:provider/provider.dart';
import 'package:soil_test/Services/LanguageProvider.dart';

// Inside a Widget's build method:
final s = Provider.of<LanguageProvider>(context).strings;

Text(s.welcomeBack)
Text(s.soilAnalysis)
```

For one-time reads inside async methods (e.g., validation, snackbars):

```dart
final s = Provider.of<LanguageProvider>(context, listen: false).strings;
```

---

## Language Selection Access Points

| Location            | Description                                    |
|---------------------|------------------------------------------------|
| **Dashboard AppBar**| Language chip (shows "EN" or "ಕನ್ನಡ") with 🌐 icon — tap to change |
| **First Launch**    | Language selection screen shown before dashboard |

---

## Dependencies

| Package                | Version  | Purpose                          |
|------------------------|----------|----------------------------------|
| `shared_preferences`   | ^2.5.3   | Persist language choice on device |
| `provider`             | ^6.1.4   | Reactive state management        |

---

## File Reference

| File | Purpose |
|------|---------|
| `lib/Services/LanguageProvider.dart` | All translations + state management |
| `lib/Screens/LanguageSelectionScreen.dart` | Language picker UI |
| `lib/main.dart` | Provider initialization |
| `lib/Screens/SoilTest.dart` | MaterialApp with routes |
| `lib/Utils/app_strings.dart` | **Deprecated** — replaced by `AppStrings` in `LanguageProvider` |

---

## Notes

- The old `lib/Utils/app_strings.dart` mixin with `static const` strings is **no longer used** by any screen. It is kept for reference but can be safely deleted.
- All strings are **compile-time constants** (`static const AppStrings`), so there is zero runtime overhead for string creation.
- The language preference survives app restarts and reinstalls (SharedPreferences).
