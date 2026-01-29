import 'package:cloud_firestore/cloud_firestore.dart';

/// Model for a deck rating (1-5 stars with optional review)
class DeckRating {
  final String id;
  final String publicDeckId;
  final String userId;
  final String? userName;
  final int rating; // 1-5 stars
  final String? review;
  final DateTime createdAt;
  final DateTime updatedAt;

  DeckRating({
    required this.id,
    required this.publicDeckId,
    required this.userId,
    this.userName,
    required this.rating,
    this.review,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : assert(rating >= 1 && rating <= 5, 'Rating must be between 1 and 5'),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  DeckRating copyWith({
    String? id,
    String? publicDeckId,
    String? userId,
    String? userName,
    int? rating,
    String? review,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeckRating(
      id: id ?? this.id,
      publicDeckId: publicDeckId ?? this.publicDeckId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'public_deck_id': publicDeckId,
      'user_id': userId,
      'user_name': userName,
      'rating': rating,
      'review': review,
      'created_at': Timestamp.fromDate(createdAt),
      'updated_at': Timestamp.fromDate(updatedAt),
    };
  }

  factory DeckRating.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return DeckRating(
      id: doc.id,
      publicDeckId: data['public_deck_id'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String?,
      rating: data['rating'] as int,
      review: data['review'] as String?,
      createdAt: (data['created_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updated_at'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DeckRating.fromMap(Map<String, dynamic> data) {
    return DeckRating(
      id: data['id'] as String,
      publicDeckId: data['public_deck_id'] as String,
      userId: data['user_id'] as String,
      userName: data['user_name'] as String?,
      rating: data['rating'] as int,
      review: data['review'] as String?,
      createdAt: data['created_at'] is DateTime
          ? data['created_at'] as DateTime
          : DateTime.now(),
      updatedAt: data['updated_at'] is DateTime
          ? data['updated_at'] as DateTime
          : DateTime.now(),
    );
  }

  @override
  String toString() => 'DeckRating(id: $id, rating: $rating)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeckRating && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
