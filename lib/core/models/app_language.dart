/// Supported languages for the app
enum AppLanguage {
  english('en', 'English', 'English', 'Latin'),
  hindi('hi', 'Hindi', 'हिन्दी', 'Devanagari'),
  tamil('ta', 'Tamil', 'தமிழ்', 'Tamil'),
  telugu('te', 'Telugu', 'తెలుగు', 'Telugu'),
  bengali('bn', 'Bengali', 'বাংলা', 'Bengali'),
  marathi('mr', 'Marathi', 'मराठी', 'Devanagari'),
  gujarati('gu', 'Gujarati', 'ગુજરાતી', 'Gujarati'),
  kannada('kn', 'Kannada', 'ಕನ್ನಡ', 'Kannada'),
  malayalam('ml', 'Malayalam', 'മലയാളം', 'Malayalam'),
  punjabi('pa', 'Punjabi', 'ਪੰਜਾਬੀ', 'Gurmukhi'),
  odia('or', 'Odia', 'ଓଡ଼ିଆ', 'Odia'),
  assamese('as', 'Assamese', 'অসমীয়া', 'Bengali');

  final String code;
  final String englishName;
  final String nativeName;
  final String script;

  const AppLanguage(this.code, this.englishName, this.nativeName, this.script);

  /// Display name showing both English and native name
  String get displayName => '$englishName ($nativeName)';

  /// Get language from code
  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.english,
    );
  }
}
