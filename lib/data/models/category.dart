/// Predefined categories for public decks
class Category {
  final String id;
  final String name;
  final String nameVi;
  final String? icon;
  final int order;
  /// Language code this category is restricted to (null = universal)
  final String? language;

  const Category({
    required this.id,
    required this.name,
    required this.nameVi,
    this.icon,
    this.order = 0,
    this.language,
  });

  /// Get localized name
  String getLocalizedName(String locale) {
    return locale == 'vi' ? nameVi : name;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'name_vi': nameVi,
      'icon': icon,
      'order': order,
      if (language != null) 'language': language,
    };
  }

  /// Convert to Firestore document
  Map<String, dynamic> toFirestore() => toMap();

  /// Alias for predefined categories (for seeder compatibility)
  static List<Category> get predefinedCategories => predefined;

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      nameVi: map['name_vi'] as String? ?? map['name'] as String,
      icon: map['icon'] as String?,
      order: map['order'] as int? ?? 0,
      language: map['language'] as String?,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Predefined categories
  static const List<Category> predefined = [
    // === Universal categories ===
    Category(id: 'travel', name: 'Travel', nameVi: 'Du lịch', icon: 'flight', order: 1),
    Category(id: 'business', name: 'Business', nameVi: 'Công việc', icon: 'business', order: 2),
    Category(id: 'daily', name: 'Daily Life', nameVi: 'Hằng ngày', icon: 'home', order: 3),
    Category(id: 'academic', name: 'Academic', nameVi: 'Học thuật', icon: 'menu_book', order: 4),
    Category(id: 'slang', name: 'Slang & Idioms', nameVi: 'Tiếng lóng', icon: 'chat_bubble', order: 5),

    // === English-only categories ===
    Category(id: 'toeic', name: 'TOEIC', nameVi: 'TOEIC', icon: 'school', language: 'en', order: 10),
    Category(id: 'ielts', name: 'IELTS', nameVi: 'IELTS', icon: 'school', language: 'en', order: 11),
    Category(id: 'toefl', name: 'TOEFL', nameVi: 'TOEFL', icon: 'school', language: 'en', order: 12),

    // === Japanese-only categories ===
    Category(id: 'jlpt', name: 'JLPT', nameVi: 'JLPT', icon: 'translate', language: 'ja', order: 20),
    Category(id: 'jlpt_n5', name: 'JLPT N5', nameVi: 'JLPT N5', icon: 'translate', language: 'ja', order: 21),
    Category(id: 'jlpt_n4', name: 'JLPT N4', nameVi: 'JLPT N4', icon: 'translate', language: 'ja', order: 22),
    Category(id: 'jlpt_n3', name: 'JLPT N3', nameVi: 'JLPT N3', icon: 'translate', language: 'ja', order: 23),
    Category(id: 'jlpt_n2', name: 'JLPT N2', nameVi: 'JLPT N2', icon: 'translate', language: 'ja', order: 24),
    Category(id: 'jlpt_n1', name: 'JLPT N1', nameVi: 'JLPT N1', icon: 'translate', language: 'ja', order: 25),

    // === Chinese-only categories ===
    Category(id: 'hsk', name: 'HSK', nameVi: 'HSK', icon: 'translate', language: 'zh', order: 30),
    Category(id: 'hsk_1', name: 'HSK 1', nameVi: 'HSK 1', icon: 'translate', language: 'zh', order: 31),
    Category(id: 'hsk_2', name: 'HSK 2', nameVi: 'HSK 2', icon: 'translate', language: 'zh', order: 32),
    Category(id: 'hsk_3', name: 'HSK 3', nameVi: 'HSK 3', icon: 'translate', language: 'zh', order: 33),
    Category(id: 'hsk_4', name: 'HSK 4', nameVi: 'HSK 4', icon: 'translate', language: 'zh', order: 34),
    Category(id: 'hsk_5', name: 'HSK 5', nameVi: 'HSK 5', icon: 'translate', language: 'zh', order: 35),
    Category(id: 'hsk_6', name: 'HSK 6', nameVi: 'HSK 6', icon: 'translate', language: 'zh', order: 36),

    // === Always last ===
    Category(id: 'other', name: 'Other', nameVi: 'Khác', icon: 'more_horiz', order: 99),
  ];

  /// Get categories available for a specific language.
  /// Returns universal categories + language-specific categories.
  /// If [langCode] is null (All), returns all predefined categories.
  static List<Category> forLanguage(String? langCode) {
    if (langCode == null) return predefined;
    return predefined
        .where((c) => c.language == null || c.language == langCode)
        .toList();
  }

  /// Get category by ID
  static Category? getById(String id) {
    try {
      return predefined.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
