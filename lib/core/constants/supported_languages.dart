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
