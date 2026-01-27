/// Predefined categories for public decks
class Category {
  final String id;
  final String name;
  final String nameVi;
  final String? icon;
  final int order;

  const Category({
    required this.id,
    required this.name,
    required this.nameVi,
    this.icon,
    this.order = 0,
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
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      nameVi: map['name_vi'] as String? ?? map['name'] as String,
      icon: map['icon'] as String?,
      order: map['order'] as int? ?? 0,
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
    Category(id: 'toeic', name: 'TOEIC', nameVi: 'TOEIC', icon: 'school', order: 1),
    Category(id: 'ielts', name: 'IELTS', nameVi: 'IELTS', icon: 'school', order: 2),
    Category(id: 'toefl', name: 'TOEFL', nameVi: 'TOEFL', icon: 'school', order: 3),
    Category(id: 'jlpt', name: 'JLPT', nameVi: 'JLPT', icon: 'translate', order: 4),
    Category(id: 'hsk', name: 'HSK', nameVi: 'HSK', icon: 'translate', order: 5),
    Category(id: 'travel', name: 'Travel', nameVi: 'Du lịch', icon: 'flight', order: 6),
    Category(id: 'business', name: 'Business', nameVi: 'Kinh doanh', icon: 'business', order: 7),
    Category(id: 'daily', name: 'Daily Life', nameVi: 'Hằng ngày', icon: 'home', order: 8),
    Category(id: 'academic', name: 'Academic', nameVi: 'Học thuật', icon: 'menu_book', order: 9),
    Category(id: 'slang', name: 'Slang & Idioms', nameVi: 'Tiếng lóng', icon: 'chat_bubble', order: 10),
    Category(id: 'other', name: 'Other', nameVi: 'Khác', icon: 'more_horiz', order: 99),
  ];

  /// Get category by ID
  static Category? getById(String id) {
    try {
      return predefined.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }
}
