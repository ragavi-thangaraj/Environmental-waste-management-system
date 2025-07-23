import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<Locale> supportedLocales = [
    Locale('en', 'US'),
    Locale('ta', 'IN'),
    Locale('hi', 'IN'),
  ];

  // Common translations
  String get appName => _localizedValues[locale.languageCode]!['app_name']!;
  String get home => _localizedValues[locale.languageCode]!['home']!;
  String get profile => _localizedValues[locale.languageCode]!['profile']!;
  String get settings => _localizedValues[locale.languageCode]!['settings']!;
  String get logout => _localizedValues[locale.languageCode]!['logout']!;
  String get loading => _localizedValues[locale.languageCode]!['loading']!;
  String get error => _localizedValues[locale.languageCode]!['error']!;
  String get success => _localizedValues[locale.languageCode]!['success']!;
  String get cancel => _localizedValues[locale.languageCode]!['cancel']!;
  String get ok => _localizedValues[locale.languageCode]!['ok']!;
  String get save => _localizedValues[locale.languageCode]!['save']!;
  String get delete => _localizedValues[locale.languageCode]!['delete']!;
  String get edit => _localizedValues[locale.languageCode]!['edit']!;
  String get submit => _localizedValues[locale.languageCode]!['submit']!;
  String get retry => _localizedValues[locale.languageCode]!['retry']!;

  // Home page translations
  String get savingEarth => _localizedValues[locale.languageCode]!['saving_earth']!;
  String get subtext => _localizedValues[locale.languageCode]!['subtext']!;
  String get recycleTitle => _localizedValues[locale.languageCode]!['recycle_title']!;
  String get recycleSubtitle => _localizedValues[locale.languageCode]!['recycle_subtitle']!;
  String get wellnessTitle => _localizedValues[locale.languageCode]!['wellness_title']!;
  String get wellnessSubtitle => _localizedValues[locale.languageCode]!['wellness_subtitle']!;
  String get dailyChallengeTitle => _localizedValues[locale.languageCode]!['daily_challenge_title']!;
  String get dailyChallengeSubtitle => _localizedValues[locale.languageCode]!['daily_challenge_subtitle']!;

  // Wellness page translations
  String get chooseImage => _localizedValues[locale.languageCode]!['choose_image']!;
  String get selectImage => _localizedValues[locale.languageCode]!['select_image']!;
  String get analyzingImage => _localizedValues[locale.languageCode]!['analyzing_image']!;
  String get camera => _localizedValues[locale.languageCode]!['camera']!;
  String get gallery => _localizedValues[locale.languageCode]!['gallery']!;
  String get chooseImageSource => _localizedValues[locale.languageCode]!['choose_image_source']!;

  // Task page translations
  String get ecoAdventures => _localizedValues[locale.languageCode]!['eco_adventures']!;
  String get completeMissions => _localizedValues[locale.languageCode]!['complete_missions']!;
  String get progress => _localizedValues[locale.languageCode]!['progress']!;
  String get completed => _localizedValues[locale.languageCode]!['completed']!;
  String get continueAdventure => _localizedValues[locale.languageCode]!['continue_adventure']!;

  // Game titles and descriptions
  String get oceanHero => _localizedValues[locale.languageCode]!['ocean_hero']!;
  String get oceanHeroDesc => _localizedValues[locale.languageCode]!['ocean_hero_desc']!;
  String get sortingChampion => _localizedValues[locale.languageCode]!['sorting_champion']!;
  String get sortingChampionDesc => _localizedValues[locale.languageCode]!['sorting_champion_desc']!;
  String get gardenGuardian => _localizedValues[locale.languageCode]!['garden_guardian']!;
  String get gardenGuardianDesc => _localizedValues[locale.languageCode]!['garden_guardian_desc']!;
  String get energyDetective => _localizedValues[locale.languageCode]!['energy_detective']!;
  String get energyDetectiveDesc => _localizedValues[locale.languageCode]!['energy_detective_desc']!;
  String get waterWizard => _localizedValues[locale.languageCode]!['water_wizard']!;
  String get waterWizardDesc => _localizedValues[locale.languageCode]!['water_wizard_desc']!;
  String get ecoArtist => _localizedValues[locale.languageCode]!['eco_artist']!;
  String get ecoArtistDesc => _localizedValues[locale.languageCode]!['eco_artist_desc']!;

  // Difficulty levels
  String get easy => _localizedValues[locale.languageCode]!['easy']!;
  String get medium => _localizedValues[locale.languageCode]!['medium']!;
  String get hard => _localizedValues[locale.languageCode]!['hard']!;

  // Profile page translations
  String get editProfile => _localizedValues[locale.languageCode]!['edit_profile']!;
  String get totalScore => _localizedValues[locale.languageCode]!['total_score']!;
  String get streak => _localizedValues[locale.languageCode]!['streak']!;
  String get lastCompletion => _localizedValues[locale.languageCode]!['last_completion']!;
  String get noStreak => _localizedValues[locale.languageCode]!['no_streak']!;
  String get days => _localizedValues[locale.languageCode]!['days']!;

  // Disposal page translations
  String get disposalMeasures => _localizedValues[locale.languageCode]!['disposal_measures']!;
  String get whyImportant => _localizedValues[locale.languageCode]!['why_important']!;
  String get watchLearn => _localizedValues[locale.languageCode]!['watch_learn']!;
  String get tasksToComplete => _localizedValues[locale.languageCode]!['tasks_to_complete']!;
  String get markComplete => _localizedValues[locale.languageCode]!['mark_complete']!;
  String get clean => _localizedValues[locale.languageCode]!['clean']!;
  String get help => _localizedValues[locale.languageCode]!['help']!;

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_name': 'Ease Earth',
      'home': 'Home',
      'profile': 'Profile',
      'settings': 'Settings',
      'logout': 'Logout',
      'loading': 'Loading...',
      'error': 'Error',
      'success': 'Success',
      'cancel': 'Cancel',
      'ok': 'OK',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'submit': 'Submit',
      'retry': 'Retry',
      'saving_earth': 'Saving Earth, One Step at a Time',
      'subtext': 'Take a step today towards a greener future 🌿🌍',
      'recycle_title': 'Recycle rather than dump!',
      'recycle_subtitle': 'Discover ways to live sustainably.',
      'wellness_title': 'Wellness & Environment',
      'wellness_subtitle': 'Stay healthy while saving the planet.',
      'daily_challenge_title': 'Daily Green Challenge',
      'daily_challenge_subtitle': 'A new challenge every day!',
      'choose_image': 'Choose an Image',
      'select_image': 'Select Image',
      'analyzing_image': 'Analyzing Image...',
      'camera': 'Camera',
      'gallery': 'Gallery',
      'choose_image_source': 'Choose Image Source',
      'eco_adventures': '🌍 Eco Adventures',
      'complete_missions': 'Complete missions to unlock new adventures!',
      'progress': 'Progress',
      'completed': 'completed',
      'continue_adventure': 'Continue Adventure',
      'ocean_hero': 'Ocean Hero',
      'ocean_hero_desc': 'Save marine life by cleaning the ocean',
      'sorting_champion': 'Sorting Champion',
      'sorting_champion_desc': 'Master the art of waste separation',
      'garden_guardian': 'Garden Guardian',
      'garden_guardian_desc': 'Create your own green paradise',
      'energy_detective': 'Energy Detective',
      'energy_detective_desc': 'Find and fix energy waste',
      'water_wizard': 'Water Wizard',
      'water_wizard_desc': 'Protect our precious water resources',
      'eco_artist': 'Eco Artist',
      'eco_artist_desc': 'Turn trash into treasure',
      'easy': 'Easy',
      'medium': 'Medium',
      'hard': 'Hard',
      'edit_profile': 'Edit Profile',
      'total_score': 'Total Score',
      'streak': 'Streak',
      'last_completion': 'Last Completion',
      'no_streak': 'No streak',
      'days': 'days',
      'disposal_measures': 'Disposal Measures',
      'why_important': 'Why is this Important?',
      'watch_learn': 'Watch & Learn',
      'tasks_to_complete': 'Tasks to Complete',
      'mark_complete': 'Mark as Complete',
      'clean': 'Clean',
      'help': 'Help',
    },
    'ta': {
      'app_name': 'பூமி எளிமை',
      'home': 'வீடு',
      'profile': 'சுயவிவரம்',
      'settings': 'அமைப்புகள்',
      'logout': 'வெளியேறு',
      'loading': 'ஏற்றுகிறது...',
      'error': 'பிழை',
      'success': 'வெற்றி',
      'cancel': 'ரத்து',
      'ok': 'சரி',
      'save': 'சேமி',
      'delete': 'நீக்கு',
      'edit': 'திருத்து',
      'submit': 'சமர்ப்பி',
      'retry': 'மீண்டும் முயற்சி',
      'saving_earth': 'பூமியை பாதுகாக்க, ஒவ்வொரு படியிலும்',
      'subtext': 'இன்று ஒரு படி முன்னேறி பசுமையான எதிர்காலத்தை நோக்கி 🌿🌍',
      'recycle_title': 'குப்பையை தூக்காமல் மறுசுழற்சி செய்யுங்கள்!',
      'recycle_subtitle': 'சூழல் பாதுகாப்பு வாழ்வு வழிகளை கண்டறியுங்கள்.',
      'wellness_title': 'நலம் & சூழல்',
      'wellness_subtitle': 'பூமியை பாதுகாக்கும் போது ஆரோக்கியமாக இருங்கள்.',
      'daily_challenge_title': 'தினசரி பசுமை சவால்',
      'daily_challenge_subtitle': 'ஒவ்வொரு நாளும் ஒரு புதிய சவால்!',
      'choose_image': 'படத்தை தேர்வு செய்யுங்கள்',
      'select_image': 'படத்தை தேர்வு செய்யுங்கள்',
      'analyzing_image': 'படத்தை பகுப்பாய்வு செய்கிறது...',
      'camera': 'கேமரா',
      'gallery': 'கேலரி',
      'choose_image_source': 'படத்தின் மூலத்தை தேர்வு செய்யுங்கள்',
      'eco_adventures': '🌍 சூழல் சாகசங்கள்',
      'complete_missions': 'புதிய சாகசங்களை திறக்க பணிகளை முடிக்கவும்!',
      'progress': 'முன்னேற்றம்',
      'completed': 'முடிந்தது',
      'continue_adventure': 'சாகசத்தை தொடரவும்',
      'ocean_hero': 'கடல் வீரன்',
      'ocean_hero_desc': 'கடலை சுத்தம் செய்து கடல் உயிரினங்களை காப்பாற்றுங்கள்',
      'sorting_champion': 'வகைப்படுத்தும் சாம்பியன்',
      'sorting_champion_desc': 'கழிவு பிரிப்பு கலையில் தேர்ச்சி பெறுங்கள்',
      'garden_guardian': 'தோட்ட காவலர்',
      'garden_guardian_desc': 'உங்கள் சொந்த பசுமை சொர்க்கத்தை உருவாக்குங்கள்',
      'energy_detective': 'ஆற்றல் துப்பறியும்',
      'energy_detective_desc': 'ஆற்றல் வீணாக்கலை கண்டறிந்து சரிசெய்யுங்கள்',
      'water_wizard': 'நீர் மந்திரவாதி',
      'water_wizard_desc': 'நமது விலைமதிப்பற்ற நீர் வளங்களை பாதுகாக்கவும்',
      'eco_artist': 'சூழல் கலைஞர்',
      'eco_artist_desc': 'குப்பையை புதையலாக மாற்றுங்கள்',
      'easy': 'எளிது',
      'medium': 'நடுத்தர',
      'hard': 'கடினம்',
      'edit_profile': 'சுயவிவரத்தை திருத்து',
      'total_score': 'மொத்த மதிப்பெண்',
      'streak': 'தொடர்ச்சி',
      'last_completion': 'கடைசி முடிவு',
      'no_streak': 'தொடர்ச்சி இல்லை',
      'days': 'நாட்கள்',
      'disposal_measures': 'அகற்றும் நடவடிக்கைகள்',
      'why_important': 'இது ஏன் முக்கியம்?',
      'watch_learn': 'பார்த்து கற்றுக்கொள்ளுங்கள்',
      'tasks_to_complete': 'முடிக்க வேண்டிய பணிகள்',
      'mark_complete': 'முடிந்ததாக குறிக்கவும்',
      'clean': 'சுத்தம்',
      'help': 'உதவி',
    },
    'hi': {
      'app_name': 'पृथ्वी आसान',
      'home': 'घर',
      'profile': 'प्रोफ़ाइल',
      'settings': 'सेटिंग्स',
      'logout': 'लॉग आउट',
      'loading': 'लोड हो रहा है...',
      'error': 'त्रुटि',
      'success': 'सफलता',
      'cancel': 'रद्द करें',
      'ok': 'ठीक है',
      'save': 'सेव करें',
      'delete': 'हटाएं',
      'edit': 'संपादित करें',
      'submit': 'जमा करें',
      'retry': 'पुनः प्रयास',
      'saving_earth': 'एक कदम में पृथ्वी बचाएं',
      'subtext': 'आज हरित भविष्य की ओर एक कदम बढ़ाएं 🌿🌍',
      'recycle_title': 'कचरे को फेंकने के बजाय रिसाइकिल करें!',
      'recycle_subtitle': 'सतत जीवन जीने के तरीके खोजें।',
      'wellness_title': 'स्वास्थ्य & पर्यावरण',
      'wellness_subtitle': 'पृथ्वी बचाते हुए स्वस्थ रहें।',
      'daily_challenge_title': 'दैनिक हरित चुनौती',
      'daily_challenge_subtitle': 'हर दिन एक नई चुनौती!',
      'choose_image': 'एक छवि चुनें',
      'select_image': 'छवि चुनें',
      'analyzing_image': 'छवि का विश्लेषण कर रहे हैं...',
      'camera': 'कैमरा',
      'gallery': 'गैलरी',
      'choose_image_source': 'छवि स्रोत चुनें',
      'eco_adventures': '🌍 पर्यावरण रोमांच',
      'complete_missions': 'नए रोमांच अनलॉक करने के लिए मिशन पूरे करें!',
      'progress': 'प्रगति',
      'completed': 'पूर्ण',
      'continue_adventure': 'रोमांच जारी रखें',
      'ocean_hero': 'समुद्री नायक',
      'ocean_hero_desc': 'समुद्र की सफाई करके समुद्री जीवन बचाएं',
      'sorting_champion': 'छंटाई चैंपियन',
      'sorting_champion_desc': 'कचरा अलगाव की कला में महारत हासिल करें',
      'garden_guardian': 'बगीचा संरक्षक',
      'garden_guardian_desc': 'अपना हरा स्वर्ग बनाएं',
      'energy_detective': 'ऊर्जा जासूस',
      'energy_detective_desc': 'ऊर्जा की बर्बादी खोजें और ठीक करें',
      'water_wizard': 'पानी जादूगर',
      'water_wizard_desc': 'हमारे कीमती जल संसाधनों की रक्षा करें',
      'eco_artist': 'पर्यावरण कलाकार',
      'eco_artist_desc': 'कचरे को खजाने में बदलें',
      'easy': 'आसान',
      'medium': 'मध्यम',
      'hard': 'कठिन',
      'edit_profile': 'प्रोफ़ाइल संपादित करें',
      'total_score': 'कुल स्कोर',
      'streak': 'लगातार',
      'last_completion': 'अंतिम पूर्णता',
      'no_streak': 'कोई लगातार नहीं',
      'days': 'दिन',
      'disposal_measures': 'निपटान उपाय',
      'why_important': 'यह क्यों महत्वपूर्ण है?',
      'watch_learn': 'देखें और सीखें',
      'tasks_to_complete': 'पूरे करने के लिए कार्य',
      'mark_complete': 'पूर्ण के रूप में चिह्नित करें',
      'clean': 'साफ',
      'help': 'मदद',
    },
  };
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'ta', 'hi'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}