import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/category.dart';

/// Utility class to seed predefined categories to Firestore
/// Run this once during initial setup or when categories need to be updated
class CategorySeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Seed all predefined categories to Firestore
  /// This is idempotent - running multiple times won't create duplicates
  Future<void> seedCategories() async {
    final batch = _firestore.batch();
    final categoriesRef = _firestore.collection('categories');

    for (final category in Category.predefinedCategories) {
      final docRef = categoriesRef.doc(category.id);
      batch.set(docRef, category.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  /// Check if categories exist in Firestore
  Future<bool> categoriesExist() async {
    final snapshot = await _firestore
        .collection('categories')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  /// Seed categories only if they don't exist
  Future<void> seedIfNeeded() async {
    final exists = await categoriesExist();
    if (!exists) {
      await seedCategories();
    }
  }
}
