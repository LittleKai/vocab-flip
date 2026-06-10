/// Model for a publicly shared deck in the library
class PublicDeck {
  final String id;
  final String? originalLocalId;
  final String authorId;
  final String authorName;
  final String name;
  final String? description;
  final String sourceLanguage;
  final String targetLanguage;
  final String categoryId;
  final List<String> tags;
  final int cardCount;
  final int version;
  final double ratingSum;
  final int ratingCount;
  final int downloadCount;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? publishedAt;
  final bool isActive;
  final String? shortId;
  final String? imageUrl;
  final String? frontFields;
  final String? backFields;
  final String? imageDisplayMode;
  final bool showBackFirst;

  PublicDeck({
    required this.id,
    this.originalLocalId,
    required this.authorId,
    required this.authorName,
    required this.name,
    this.description,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.categoryId,
    List<String>? tags,
    this.cardCount = 0,
    this.version = 1,
    this.ratingSum = 0,
    this.ratingCount = 0,
    this.downloadCount = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.publishedAt,
    this.isActive = true,
    this.shortId,
    this.imageUrl,
    this.frontFields,
    this.backFields,
    this.imageDisplayMode,
    this.showBackFirst = false,
  })  : tags = tags ?? [],
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Average rating (0-5)
  double get averageRating {
    if (ratingCount == 0) return 0;
    return ratingSum / ratingCount;
  }

  /// Check if deck has ratings
  bool get hasRatings => ratingCount > 0;

  PublicDeck copyWith({
    String? id,
    String? originalLocalId,
    String? authorId,
    String? authorName,
    String? name,
    String? description,
    String? sourceLanguage,
    String? targetLanguage,
    String? categoryId,
    List<String>? tags,
    int? cardCount,
    int? version,
    double? ratingSum,
    int? ratingCount,
    int? downloadCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? publishedAt,
    bool? isActive,
    String? shortId,
    String? imageUrl,
    String? frontFields,
    String? backFields,
    String? imageDisplayMode,
    bool? showBackFirst,
  }) {
    return PublicDeck(
      id: id ?? this.id,
      originalLocalId: originalLocalId ?? this.originalLocalId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      name: name ?? this.name,
      description: description ?? this.description,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      categoryId: categoryId ?? this.categoryId,
      tags: tags ?? this.tags,
      cardCount: cardCount ?? this.cardCount,
      version: version ?? this.version,
      ratingSum: ratingSum ?? this.ratingSum,
      ratingCount: ratingCount ?? this.ratingCount,
      downloadCount: downloadCount ?? this.downloadCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      publishedAt: publishedAt ?? this.publishedAt,
      isActive: isActive ?? this.isActive,
      shortId: shortId ?? this.shortId,
      imageUrl: imageUrl ?? this.imageUrl,
      frontFields: frontFields ?? this.frontFields,
      backFields: backFields ?? this.backFields,
      imageDisplayMode: imageDisplayMode ?? this.imageDisplayMode,
      showBackFirst: showBackFirst ?? this.showBackFirst,
    );
  }

  /// Create from REST API response (Map with parsed values)
  factory PublicDeck.fromMap(Map<String, dynamic> data) {
    return PublicDeck(
      id: data['id'] as String? ?? '',
      originalLocalId: data['original_local_id'] as String?,
      authorId: data['author_id'] as String? ?? '',
      authorName: data['author_name'] as String? ?? 'Unknown',
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      sourceLanguage: data['source_language'] as String? ?? 'en',
      targetLanguage: data['target_language'] as String? ?? 'vi',
      categoryId: data['category_id'] as String? ?? 'other',
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      cardCount: data['card_count'] as int? ?? 0,
      version: data['version'] as int? ?? 1,
      ratingSum: (data['rating_sum'] as num?)?.toDouble() ?? 0,
      ratingCount: data['rating_count'] as int? ?? 0,
      downloadCount: data['download_count'] as int? ?? 0,
      createdAt: _parseDateTime(data['created_at']),
      updatedAt: _parseDateTime(data['updated_at']),
      publishedAt: data['published_at'] != null ? _parseDateTime(data['published_at']) : null,
      isActive: data['is_active'] as bool? ?? true,
      shortId: data['short_id'] as String?,
      imageUrl: data['image_url'] as String?,
      frontFields: data['front_fields'] as String?,
      backFields: data['back_fields'] as String?,
      imageDisplayMode: data['image_display_mode'] as String?,
      showBackFirst: data['show_back_first'] as bool? ?? false,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  @override
  String toString() => 'PublicDeck(id: $id, name: $name, author: $authorName)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PublicDeck && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
