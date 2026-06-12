import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported language codes.
class LanguageCode {
  static const String english = 'en';
  static const String kannada = 'kn';
}

/// LanguageProvider manages the app's current language selection.
///
/// Persists the user's choice to [SharedPreferences] so it survives app restarts.
/// Provides localized strings via the [strings] getter.
///
/// Usage:
/// ```dart
/// // In main.dart, wrap the app with ChangeNotifierProvider:
/// ChangeNotifierProvider(create: (_) => LanguageProvider(), child: const SoilTest());
///
/// // In any screen:
/// final lang = Provider.of<LanguageProvider>(context);
/// Text(lang.strings.welcomeBack);
/// ```
class LanguageProvider extends ChangeNotifier {
  static const String _prefKey = 'app_language';

  String _currentLanguage = LanguageCode.english;
  late SharedPreferences _prefs;
  bool _isInitialized = false;

  /// Whether the provider has finished loading saved preferences.
  bool get isInitialized => _isInitialized;

  /// Current language code ('en' or 'kn').
  String get currentLanguage => _currentLanguage;

  /// Convenience flag: true when Kannada is selected.
  bool get isKannada => _currentLanguage == LanguageCode.kannada;

  /// Returns the localized strings for the current language.
  AppStrings get strings => _localizedStrings[_currentLanguage]!;

  /// Initialize the provider — call before runApp or in main().
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _currentLanguage = _prefs.getString(_prefKey) ?? LanguageCode.english;
    _isInitialized = true;
    notifyListeners();
  }

  /// Change the app language and persist the choice.
  Future<void> setLanguage(String languageCode) async {
    if (_localizedStrings.containsKey(languageCode)) {
      _currentLanguage = languageCode;
      await _prefs.setString(_prefKey, languageCode);
      notifyListeners();
    }
  }

  /// All localized string maps.
  static final Map<String, AppStrings> _localizedStrings = {
    LanguageCode.english: AppStrings.english,
    LanguageCode.kannada: AppStrings.kannada,
  };
}

// ---------------------------------------------------------------------------
// Localized string model — one instance per language.
// ---------------------------------------------------------------------------
class AppStrings {
  // ---- General ----
  final String title;
  final String fontFamilyRoboto;

  // ---- Snack bar messages ----
  final String imageCaptureSuccess;
  final String locationAcquired;

  // ---- Dashboard ----
  final String welcomeBack;
  final String soilAnalysis;
  final String recentReports;
  final String farmHealthGood;
  final String guest;

  // ---- Analysis Screen ----
  final String stepOne;
  final String stepOneInstruction;
  final String tapToOpenCamera;
  final String stepTwo;
  final String stepTwoInstruction;
  final String fetchGps;
  final String runAiAnalysis;
  final String physicalAiAnalysis;
  final String galleryMultiple;
  final String cameraSingle;
  final String fetchingLocation;
  final String uploadingProgress;
  final String errorPickingImages;
  final String locationServicesDisabled;
  final String enableLocationMessage;
  final String cancel;
  final String openSettings;
  final String noSignedInUser;
  final String uploadError;

  // ---- Report Screen ----
  final String soilReport;
  final String preparingPdf;
  final String location;
  final String testedOn;
  final String justNow;
  final String macroNutrients;
  final String nitrogen;
  final String phosphorus;
  final String potassium;
  final String physicalProperties;
  final String phLevel;
  final String moisture;
  final String soilType;
  final String aiRecommendations;
  final String irrigationAdvisory;
  final String backToDashboard;
  final String healthy;
  final String increasePhosphorus;
  final String increasePhosphorusDesc;
  final String irrigationAdvisoryDesc;
  final String optimal;
  final String slightlyDry;
  final String identifiedByVisionAi;
  final String medium;
  final String low;
  final String high;

  // ---- Processing Screen ----
  final String uploadingData;
  final String runningVisionModels;
  final String analysingNpkMoisture;
  final String generatingSoilReport;
  final String processingSoilData;

  // ---- Registration Screen ----
  final String registrationMessage;
  final String firstName;
  final String lastName;
  final String enterFirstName;
  final String enterLastName;
  final String emailAddress;
  final String enterEmailAddress;
  final String phoneNumber;
  final String enterPhoneNumber;
  final String password;
  final String confirmPassword;
  final String validatePassword;
  final String confirmPasswordMessage;
  final String passwordNotMatch;
  final String register;
  final String registeredSuccess;
  final String registrationFailed;
  final String createAccount;

  // ---- Login Screen ----
  final String loginTitle;
  final String loginSubtitle;
  final String dontHaveAccount;
  final String registerNow;
  final String orLoginWith;
  final String loginSuccess;
  final String login;
  final String loginErrorUserNotFound;
  final String loginErrorWrongPassword;
  final String loginErrorInvalidEmail;
  final String loginErrorGeneric;
  final String loggedInAs;

  // ---- Profile Screen ----
  final String myProfile;
  final String tapToChangePhoto;
  final String name;
  final String email;
  final String phone;
  final String logout;
  final String profilePhotoUpdated;
  final String errorUpdatingPhoto;

  // ---- Language Selection Screen ----
  final String chooseLanguage;
  final String chooseLanguageSubtitle;
  final String englishLabel;
  final String kannadaLabel;
  final String continueText;

  // ---- Recent Reports (mock data) ----
  final String optimalStatus;
  final String needsNitrogen;
  final String acidicLowPh;

  // ---- Misc ----
  final String noImageSelected;

  // ---- Image Quality Validation ----
  final String imageBlurry;
  final String imageTooDark;
  final String imageTooBright;
  final String imageNotSoil;
  final String imageQualityChecking;
  final String imageQualityIssue;
  final String retakeImage;

  const AppStrings({
    required this.title,
    required this.fontFamilyRoboto,
    required this.imageCaptureSuccess,
    required this.locationAcquired,
    required this.welcomeBack,
    required this.soilAnalysis,
    required this.recentReports,
    required this.farmHealthGood,
    required this.guest,
    required this.stepOne,
    required this.stepOneInstruction,
    required this.tapToOpenCamera,
    required this.stepTwo,
    required this.stepTwoInstruction,
    required this.fetchGps,
    required this.runAiAnalysis,
    required this.physicalAiAnalysis,
    required this.galleryMultiple,
    required this.cameraSingle,
    required this.fetchingLocation,
    required this.uploadingProgress,
    required this.errorPickingImages,
    required this.locationServicesDisabled,
    required this.enableLocationMessage,
    required this.cancel,
    required this.openSettings,
    required this.noSignedInUser,
    required this.uploadError,
    required this.soilReport,
    required this.preparingPdf,
    required this.location,
    required this.testedOn,
    required this.justNow,
    required this.macroNutrients,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.physicalProperties,
    required this.phLevel,
    required this.moisture,
    required this.soilType,
    required this.aiRecommendations,
    required this.irrigationAdvisory,
    required this.backToDashboard,
    required this.healthy,
    required this.increasePhosphorus,
    required this.increasePhosphorusDesc,
    required this.irrigationAdvisoryDesc,
    required this.optimal,
    required this.slightlyDry,
    required this.identifiedByVisionAi,
    required this.medium,
    required this.low,
    required this.high,
    required this.uploadingData,
    required this.runningVisionModels,
    required this.analysingNpkMoisture,
    required this.generatingSoilReport,
    required this.processingSoilData,
    required this.registrationMessage,
    required this.firstName,
    required this.lastName,
    required this.enterFirstName,
    required this.enterLastName,
    required this.emailAddress,
    required this.enterEmailAddress,
    required this.phoneNumber,
    required this.enterPhoneNumber,
    required this.password,
    required this.confirmPassword,
    required this.validatePassword,
    required this.confirmPasswordMessage,
    required this.passwordNotMatch,
    required this.register,
    required this.registeredSuccess,
    required this.registrationFailed,
    required this.createAccount,
    required this.loginTitle,
    required this.loginSubtitle,
    required this.dontHaveAccount,
    required this.registerNow,
    required this.orLoginWith,
    required this.loginSuccess,
    required this.login,
    required this.loginErrorUserNotFound,
    required this.loginErrorWrongPassword,
    required this.loginErrorInvalidEmail,
    required this.loginErrorGeneric,
    required this.loggedInAs,
    required this.myProfile,
    required this.tapToChangePhoto,
    required this.name,
    required this.email,
    required this.phone,
    required this.logout,
    required this.profilePhotoUpdated,
    required this.errorUpdatingPhoto,
    required this.chooseLanguage,
    required this.chooseLanguageSubtitle,
    required this.englishLabel,
    required this.kannadaLabel,
    required this.continueText,
    required this.optimalStatus,
    required this.needsNitrogen,
    required this.acidicLowPh,
    required this.noImageSelected,
    required this.imageBlurry,
    required this.imageTooDark,
    required this.imageTooBright,
    required this.imageNotSoil,
    required this.imageQualityChecking,
    required this.imageQualityIssue,
    required this.retakeImage,
  });

  // ======================= English =======================
  static const AppStrings english = AppStrings(
    title: 'Banas AI',
    fontFamilyRoboto: 'Roboto',
    imageCaptureSuccess: 'Image captured successfully!',
    locationAcquired: 'Location acquired.',
    welcomeBack: 'Welcome back,',
    soilAnalysis: 'New Soil Analysis',
    recentReports: 'Recent Reports',
    farmHealthGood: "Your farm's soil health is looking good.",
    guest: 'Guest',
    stepOne: 'Step 1: Capture Soil Image',
    stepOneInstruction:
        'Take a clear picture of the soil surface. Ensure good lighting for the AI to analyze physical properties.',
    tapToOpenCamera: 'Tap to open camera',
    stepTwo: 'Step 2: Tag Location',
    stepTwoInstruction:
        'We need your location to correlate with satellite data and local climate.',
    fetchGps: 'FETCH GPS',
    runAiAnalysis: 'Run AI Analysis',
    physicalAiAnalysis: 'Physical AI Analysis',
    galleryMultiple: 'Gallery (Multiple)',
    cameraSingle: 'Camera (Single)',
    fetchingLocation: 'Fetching location...',
    uploadingProgress: 'Uploading',
    errorPickingImages: 'Error picking images',
    locationServicesDisabled: 'Location Services Disabled',
    enableLocationMessage:
        'Please enable location services to proceed with the analysis.',
    cancel: 'Cancel',
    openSettings: 'Open Settings',
    noSignedInUser: 'No signed-in user; cannot upload analysis images.',
    uploadError: 'Upload Error',
    soilReport: 'Soil Report',
    preparingPdf: 'Preparing PDF to share...',
    location: 'Location:',
    testedOn: 'Tested on:',
    justNow: 'Just Now',
    macroNutrients: 'Macronutrients (NPK)',
    nitrogen: 'Nitrogen (N)',
    phosphorus: 'Phosphorus (P)',
    potassium: 'Potassium (K)',
    physicalProperties: 'Physical Properties',
    phLevel: 'pH Level',
    moisture: 'Moisture',
    soilType: 'Soil Type',
    aiRecommendations: 'AI Recommendations',
    irrigationAdvisory: 'Irrigation Advisory',
    backToDashboard: 'Back to Dashboard',
    healthy: 'HEALTHY',
    increasePhosphorus: 'Increase Phosphorus',
    increasePhosphorusDesc:
        'Apply 20kg of DAP per acre to combat low phosphorus levels before the next planting cycle.',
    irrigationAdvisoryDesc:
        'Moisture is slightly low. Recommend running drip irrigation for 2 hours this evening.',
    optimal: 'Optimal (6.0 - 7.0)',
    slightlyDry: 'Slightly Dry',
    identifiedByVisionAi: 'Identified by Vision AI',
    medium: 'Medium',
    low: 'Low',
    high: 'High',
    uploadingData: 'Uploading data to server...',
    runningVisionModels: 'Running physical AI vision models...',
    analysingNpkMoisture: 'Analyzing N-P-K & Moisture levels...',
    generatingSoilReport: 'Generating soil report and recommendations...',
    processingSoilData: 'Processing Soil Data',
    registrationMessage: 'Fill in your details to get started',
    firstName: 'First Name',
    lastName: 'Last Name',
    enterFirstName: 'Enter your first name',
    enterLastName: 'Enter your last name',
    emailAddress: 'Email Address',
    enterEmailAddress: 'Enter valid email address',
    phoneNumber: 'Phone Number',
    enterPhoneNumber: 'Enter valid phone number',
    password: 'Password',
    confirmPassword: 'Confirm Password',
    validatePassword: 'Min 6 characters required',
    confirmPasswordMessage: 'Please confirm your password',
    passwordNotMatch: 'Password does not match',
    register: 'Register',
    registeredSuccess: 'Registration Successful!',
    registrationFailed: 'Registration Failed',
    createAccount: 'Create Account',
    loginTitle: 'Welcome Back',
    loginSubtitle: 'Login to your account',
    dontHaveAccount: "Don't have an account? ",
    registerNow: 'Register Now',
    orLoginWith: 'Or login with',
    loginSuccess: 'Login Successful',
    login: 'LOGIN',
    loginErrorUserNotFound: 'No user found for that email.',
    loginErrorWrongPassword: 'Wrong password provided.',
    loginErrorInvalidEmail: 'The email address is badly formatted.',
    loginErrorGeneric: 'An error occurred',
    loggedInAs: 'Logged in as',
    myProfile: 'My Profile',
    tapToChangePhoto: 'Tap to change photo',
    name: 'Name',
    email: 'Email',
    phone: 'Phone',
    logout: 'Logout',
    profilePhotoUpdated: 'Profile photo updated!',
    errorUpdatingPhoto: 'Error updating photo',
    chooseLanguage: 'Choose Language',
    chooseLanguageSubtitle: 'Select your preferred language',
    englishLabel: 'English',
    kannadaLabel: 'ಕನ್ನಡ',
    continueText: 'Continue',
    optimalStatus: 'Optimal',
    needsNitrogen: 'Needs Nitrogen',
    acidicLowPh: 'Acidic (Low pH)',
    noImageSelected: 'Sorry No Images selected',
    imageBlurry: 'Image appears blurry. Hold the camera steady and retake.',
    imageTooDark: 'Image is too dark. Move to a well-lit area and retake.',
    imageTooBright: 'Image is overexposed. Avoid direct harsh light and retake.',
    imageNotSoil: "This doesn't appear to be a soil image. Point the camera at the soil surface.",
    imageQualityChecking: 'Checking image quality...',
    imageQualityIssue: 'Image Quality Issue',
    retakeImage: 'Retake Image',
  );

  // ======================= Kannada =======================
  static const AppStrings kannada = AppStrings(
    title: 'Banas AI',
    fontFamilyRoboto: 'Roboto',
    imageCaptureSuccess:
        'ಚಿತ್ರ ಯಶಸ್ವವಾಗಿ ಕ್ಯಾಪ್ಚ್ ಮಾಡಲಾಗಿದೆ!',
    locationAcquired:
        'ಸ್ಥಳವನ್ನು ಪಡೆಯಲಾಗಿದೆ.',
    welcomeBack: 'ಮತ್ತೇ ಸ್ವಾಗತ,',
    soilAnalysis:
        'ಹೆಚ್ಚು ಮಣ್ಣಿನ ವಿಶ್ಲೇಷಣೆ',
    recentReports:
        'ಇತ್ತೀಚಿನ ವರದಿಗಳು',
    farmHealthGood:
        'ನಿಮ್ಮ ಕೃಷಿ ಭೂಮಿಯ ಮಣ್ಣಿನ ಆರೋಗ್ಯ ಚೆನ್ನಾಗಿದೆ.',
    guest: 'ಅತಿಥಿ',
    stepOne:
        'ಹಂತ 1: ಮಣ್ಣಿನ ಚಿತ್ರ ತೆಗೆದುಕೊಳ್ಳಿ',
    stepOneInstruction:
        'ಮಣ್ಣಿನ ಮೇಲ್ಮೈಯ ಚಿತ್ರವನ್ನು ಸ್ಪಷ್ಟವಾಗಿ ತೆಗೆದುಕೊಳ್ಳಿ. AI ಭौತಿಕ ಗುಣಲಕ್ಷಣಗಳನ್ನು ವಿಶ್ಲೇಷಿಸಲು ಉತ್ತಮ ಬೆಳಕು ಇರಲಿ.',
    tapToOpenCamera:
        'ಕ್ಯಾಮೆರಾ ತೆರೆಯಿಕೊಳ್ಳಿ',
    stepTwo:
        'ಹಂತ 2: ಸ್ಥಳವನ್ನು ಟ್ಯಾಗ್ ಮಾಡಿ',
    stepTwoInstruction:
        'ಉಪಗ್ರಹ ದತ್ತಾಂಶ ಮತ್ತು ಸ್ಥಳೀಯ ಹವಾಮಾನದೊಂದಿಗೆ ಸಂರೋಧಿಸಲು ನಿಮ್ಮ ಸ್ಥಳದ ಅಗತ್ಯ ಬೇಕು.',
    fetchGps: 'GPS ಪಡೆಯಿರಿ',
    runAiAnalysis: 'AI ವಿಶ್ಲೇಷಣೆ ನಡೆಸಿ',
    physicalAiAnalysis:
        'ಭೌತಿಕ AI ವಿಶ್ಲೇಷಣೆ',
    galleryMultiple:
        'ಗ್ಯಾಲರಿ (ಅನೇಕ)',
    cameraSingle:
        'ಕ್ಯಾಮೆರಾ (ಒಂದು)',
    fetchingLocation:
        'ಸ್ಥಳವನ್ನು ಪಡೆಯುವುದು...',
    uploadingProgress:
        'ಅಪ್ಲೋಡ್ ಆಗುತಿದೆ',
    errorPickingImages:
        'ಚಿತ್ರಗಳನ್ನು ಆಯ್ಕೆ ಮಾಡಲು ದೋಷ',
    locationServicesDisabled:
        'ಸ್ಥಳ ಸೇವೆಗಳು ನಿಷ್ಕ್ರಿಯಗೊಂಡಿವೆ',
    enableLocationMessage:
        'ವಿಶ್ಲೇಷಣೆಯೊಂದಿಗೆ ಮುಂದುವರೆಯಲು ದಯವಿಟ್ಟು ಸ್ಥಳ ಸೇವೆಗಳನ್ನು ಸಕ್ರಿಯಗೊಳಿಸಿ.',
    cancel: 'ರದ್ದುಮಾಡಿ',
    openSettings:
        'ಸೆಟ್ಟಿಂಗ್ಸ್ ತೆರೆಯಿರಿ',
    noSignedInUser:
        'ಸೈನ್-ಇನ್ ಆದ ಬಳಕೆದಾರರಿಲ್ಲ; ಚಿತ್ರಗಳನ್ನು ಅಪ್ಲೋಡ್ ಮಾಡಲಾಗುವುದಿಲ್ಲ.',
    uploadError: 'ಅಪ್ಲೋಡ್ ದೋಷ',
    soilReport: 'ಮಣ್ಣಿನ ವರದಿ',
    preparingPdf: 'PDF ಹಂಚಿಕೆಯಲಾಗುತಿದೆ...',
    location: 'ಸ್ಥಳ:',
    testedOn: 'ಪರೀಕ್ಷೆ ಮಾಡಿದ ದಿನಾಂಕ:',
    justNow: 'ಇದೀಗ',
    macroNutrients:
        'ಪೋಷಕಾಂಶಗಳು (NPK)',
    nitrogen: 'ನೈಟ್ರೋಜನ್ (N)',
    phosphorus: 'ಫಾಸ್ಫರಸ್ (P)',
    potassium: 'ಪೊಟ್ಯಾಸಿಯಮ್ (K)',
    physicalProperties:
        'ಭौತಿಕ ಗುಣಲಕ್ಷಣಗಳು',
    phLevel: 'pH ಮಟ್ಟ',
    moisture: 'ತೇವಿಕೆ',
    soilType: 'ಮಣ್ಣಿನ ಬಗೆ',
    aiRecommendations: 'AI ಶಿಫಾರಸುಗಳು',
    irrigationAdvisory:
        'ನೀರಾವರಿ ಸಲಹೆ',
    backToDashboard:
        'ಡ್ಯಾಶ್ಬೋರ್ಡ್‌ಗೆ ಹಿಂದೆ ಹೋಗಿ',
    healthy: 'ಆರೋಗ್ಯಕರ',
    increasePhosphorus:
        'ಫಾಸ್ಫರಸ್ ಹೆಚ್ಚು ಮಾಡಿ',
    increasePhosphorusDesc:
        'ಮುಂದಿನ ಬಿತ್ತುವಿಕೆಗೆ ಮುಂಚೆ ಪ್ರತಿ ಎಕರೆ 20 ಕೆಜಿ DAP ಹಾಕಿ.',
    irrigationAdvisoryDesc:
        'ತೇವಿಕೆ ಸ್ವಲ್ಪ ಕಡಿಮೆಯಿದೆ. ಇಂದು ಸಂಜೆ 2 ಗಂಟೆ ಡ್ರಿಪ್ ನೀರಾವರಿ ಚಲಾಯಿಸಿ ಎಂದು ಶಿಫಾರಸು ಮಾಡುತ್ತೇವೆ.',
    optimal: 'ಉತ್ತಮ (6.0 - 7.0)',
    slightlyDry: 'ಸ್ವಲ್ಪ ಒಣಗಿದೆ',
    identifiedByVisionAi: 'Vision AI ಗುರುತಿಸಿದೆ',
    medium: 'ಮಧ್ಯಮ',
    low: 'ಕಡಿಮೆ',
    high: 'ಹೆಚ್ಚು',
    uploadingData:
        'ಸರ್ವರ್‌ಗೆ ದತ್ತಾಂಶ ಕಳುಹಿಯುವುದು...',
    runningVisionModels:
        'ಭौತಿಕ AI ವಿಷನ್ ಮಾಡೆಲ್‌ಗಳನ್ನು ಚಲಾಯಿಸುವುದು...',
    analysingNpkMoisture:
        'N-P-K ಮತ್ತು ತೇವಿಕೆ ಮಟ್ಟಗಳನ್ನು ವಿಶ್ಲೇಷಿಸುವುದು...',
    generatingSoilReport:
        'ಮಣ್ಣಿನ ವರದಿ ಮತ್ತು ಶಿಫಾರಸುಗಳನ್ನು ಉಂಟುಮಾಡುವುದು...',
    processingSoilData:
        'ಮಣ್ಣಿನ ದತ್ತಾಂಶ ಸಂಸ್ಕರಿಸುವುದೆ',
    registrationMessage:
        'ಪ್ರಾರಂಭಿಸಲು ನಿಮ್ಮ ಮಾಹಿತಿ ತುಂಬಿಸಿ',
    firstName: 'ಮೊದಲಿನ ಹೆಸರು',
    lastName: 'ಕೊನೆಯ ಹೆಸರು',
    enterFirstName:
        'ನಿಮ್ಮ ಮೊದಲಿನ ಹೆಸರು ನಮೂದಿಸಿ',
    enterLastName:
        'ನಿಮ್ಮ ಕೊನೆಯ ಹೆಸರು ನಮೂದಿಸಿ',
    emailAddress: 'ಇಮೇಲ್ ವಿಳಾಸ',
    enterEmailAddress:
        'ಸರಿಯಾದ ಇಮೇಲ್ ವಿಳಾಸ ನಮೂದಿಸಿ',
    phoneNumber: 'ಫೋನ್ ನಂಬರ್',
    enterPhoneNumber:
        'ಸರಿಯಾದ ಫೋನ್ ನಂಬರ್ ನಮೂದಿಸಿ',
    password: 'ಪಾಸ್‌ವರ್ಡ್',
    confirmPassword:
        'ಪಾಸ್‌ವರ್ಡ್ ಖಚಿತಪಡಿಸಿ',
    validatePassword:
        'ಕನಿಷ್ಟ 6 ಅಕ್ಷರಗಳು ಬೇಕು',
    confirmPasswordMessage:
        'ದಯವಿಟ್ಟು ಪಾಸ್‌ವರ್ಡ್ ಖಚಿತಪಡಿಸಿ',
    passwordNotMatch:
        'ಪಾಸ್‌ವರ್ಡ್ ಹೊಂದಾಗುವುದಿಲ್ಲ',
    register: 'ನೋಂದಣಿ',
    registeredSuccess: 'ನೋಂದಣಿ ಯಶಸ್ವ!',
    registrationFailed: 'ನೋಂದಣಿ ವಿಫಲವಾಯಿತು',
    createAccount: 'ಖಾತೆ ರಚಿಸಿ',
    loginTitle: 'ಮತ್ತೇ ಸ್ವಾಗತ',
    loginSubtitle: 'ನಿಮ್ಮ ಖಾತೆಗೆ ಲಾಗಿನ್ ಮಾಡಿ',
    dontHaveAccount: 'ಖಾತೆ ಇಲ್ಲ? ',
    registerNow: 'ಇದೀಗ ನೋಂದಣಿಕೊಳ್ಳಿ',
    orLoginWith:
        'ಅಥವಾ ಇದರೆಂದಿಗೆ ಲಾಗಿನ್ ಮಾಡಿ',
    loginSuccess: 'ಲಾಗಿನ್ ಯಶಸ್ವ',
    login: 'ಲಾಗಿನ್',
    loginErrorUserNotFound:
        'ಆ ಇಮೇಲ್‌ಗೆ ಬಳಕೆದಾರ ಕಂಡುವುದಿಲ್ಲ.',
    loginErrorWrongPassword:
        'ತಪ್ಪು ಪಾಸ್‌ವರ್ಡ್ ಒದಗಿಸಲಾಗಿದೆ.',
    loginErrorInvalidEmail:
        'ಇಮೇಲ್ ವಿಳಾಸ ಸರಿಯಿಲ್ಲ.',
    loginErrorGeneric: 'ದೋಷ ಸಂಭವಿಸಿದೆ',
    loggedInAs: 'ಲಾಗಿನ್ ಆಗಿದೆ',
    myProfile: 'ನನ್ನ ಪ್ರೋಫೈಲ್',
    tapToChangePhoto:
        'ಫೋಟೋ ಬದಲಾಯಿಸಲು ಇಲ್ಲಿ',
    name: 'ಹೆಸರು',
    email: 'ಇಮೇಲ್',
    phone: 'ಫೋನ್',
    logout: 'ಲಾಗ್‌ಔಟ್',
    profilePhotoUpdated:
        'ಪ್ರೋಫೈಲ್ ಫೋಟೋ ಬದಲಾಯಿದೆ!',
    errorUpdatingPhoto:
        'ಫೋಟೋ ಬದಲಾಯಿಸುವುದು ದೋಷ',
    chooseLanguage: 'ಭಾಷೆ ಆಯ್ಕೆ ಮಾಡಿ',
    chooseLanguageSubtitle:
        'ನಿಮ್ಮ ಇಚ್ಛಿತ ಭಾಷೆಯನ್ನು ಆಯ್ಕೆ ಮಾಡಿ',
    englishLabel: 'English',
    kannadaLabel: 'ಕನ್ನಡ',
    continueText: 'ಮುಂದುವರೆಯಿರಿ',
    optimalStatus: 'ಉತ್ತಮ',
    needsNitrogen: 'ನೈಟ್ರೋಜನ್ ಬೇಕು',
    acidicLowPh: 'ಆಮ್ಲ (ಕಡಿಮೆ pH)',
    noImageSelected:
        'ಕ್ಷಮಿಸಿ, ಯಾವುದೇ ಚಿತ್ರಗಳು ಆಯ್ಕೆಯಾಗಿಲ್ಲ',
    imageBlurry: 'ಚಿತ್ರ ಮಸುಕಾಗಿದೆ. ಕ್ಯಾಮೆರಾ ಸ್ಥಿರವಾಗಿ ಹಿಡಿದು ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageTooDark: 'ಚಿತ್ರ ತುಂಬಾ ಕತ್ತಲೆಯಾಗಿದೆ. ಉತ್ತಮ ಬೆಳಕಿನ ಸ್ಥಳಕ್ಕೆ ಹೋಗಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageTooBright: 'ಚಿತ್ರ ಅತಿಯಾಗಿ ಪ್ರಕಾಶಮಾನವಾಗಿದೆ. ನೇರ ಬೆಳಕನ್ನು ತಪ್ಪಿಸಿ ಮತ್ತೆ ತೆಗೆಯಿರಿ.',
    imageNotSoil: 'ಇದು ಮಣ್ಣಿನ ಚಿತ್ರವಾಗಿ ಕಂಡುಬಂದಿಲ್ಲ. ಕ್ಯಾಮೆರಾ ಮಣ್ಣಿನ ಮೇಲ್ಮೈಗೆ ಹಿಡಿಯಿರಿ.',
    imageQualityChecking: 'ಚಿತ್ರ ಗುಣಮಟ್ಟ ಪರಿಶೀಲಿಸಲಾಗುತ್ತಿದೆ...',
    imageQualityIssue: 'ಚಿತ್ರ ಗುಣಮಟ್ಟದ ಸಮಸ್ಯೆ',
    retakeImage: 'ಚಿತ್ರ ಮತ್ತೆ ತೆಗೆಯಿರಿ',
  );
}
