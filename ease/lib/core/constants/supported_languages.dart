class LanguageMapper {
  static final Map<String, String> languageToISOCode = {
    'arabic': 'ar',
    'bengali': 'bn',
    'chinese': 'zh',
    'czech': 'cs',
    'danish': 'da',
    'dutch': 'nl',
    'english': 'en',
    'finnish': 'fi',
    'french': 'fr',
    'german': 'de',
    'greek': 'el',
    'gujarati': 'gu',
    'hindi': 'hi',
    'hungarian': 'hu',
    'indonesian': 'id',
    'italian': 'it',
    'japanese': 'ja',
    'kannada': 'kn',
    'korean': 'ko',
    'malayalam': 'ml',
    'marathi': 'mr',
    'norwegian': 'no',
    'persian': 'fa',
    'polish': 'pl',
    'portuguese': 'pt',
    'punjabi': 'pa',
    'romanian': 'ro',
    'russian': 'ru',
    'slovak': 'sk',
    'spanish': 'es',
    'swedish': 'sv',
    'tamil': 'ta',
    'telugu': 'te',
    'thai': 'th',
    'turkish': 'tr',
    'ukrainian': 'uk',
    'urdu': 'ur',
    'vietnamese': 'vi'
  };

  static String getLanguageCode(String languageName) {
    final code = languageToISOCode[languageName.toLowerCase()];
    if (code == null) {
      throw Exception('Unsupported language: $languageName');
    }
    return code;
  }
}