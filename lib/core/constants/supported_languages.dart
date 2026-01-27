enum SupportedLanguage {
  english('en', 'English', 'Tiếng Anh', '🇺🇸'),
  vietnamese('vi', 'Vietnamese', 'Tiếng Việt', '🇻🇳'),
  japanese('ja', 'Japanese', 'Tiếng Nhật', '🇯🇵'),
  chinese('zh', 'Chinese', 'Tiếng Trung', '🇨🇳');

  const SupportedLanguage(this.code, this.nameEn, this.nameVi, this.flag);

  final String code;
  final String nameEn;
  final String nameVi;
  final String flag;

  /// Get native name (same as nameEn for now)
  String get nativeName => nameEn;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }

  String getName(String locale) {
    return locale == 'vi' ? nameVi : nameEn;
  }
}

class LanguagePair {
  final SupportedLanguage source;
  final SupportedLanguage target;

  const LanguagePair({required this.source, required this.target});

  static const List<LanguagePair> supportedPairs = [
    LanguagePair(source: SupportedLanguage.english, target: SupportedLanguage.vietnamese),
    LanguagePair(source: SupportedLanguage.japanese, target: SupportedLanguage.vietnamese),
    LanguagePair(source: SupportedLanguage.chinese, target: SupportedLanguage.vietnamese),
  ];
}
