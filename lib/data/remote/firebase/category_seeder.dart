import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../../models/category.dart';
import 'firestore_rest_client.dart';

/// Utility class to seed predefined categories to Firestore
/// Run this once during initial setup or when categories need to be updated
class CategorySeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreRestClient _restClient = FirestoreRestClient();

  bool get _useRest => FirestoreRestClient.shouldUseRest;

  /// Seed all predefined categories to Firestore
  /// This is idempotent - running multiple times won't create duplicates
  Future<void> seedCategories() async {
    if (_useRest) {
      await _seedCategoriesRest();
    } else {
      await _seedCategoriesNative();
    }
  }

  Future<void> _seedCategoriesNative() async {
    final batch = _firestore.batch();
    final categoriesRef = _firestore.collection('categories');

    for (final category in Category.predefinedCategories) {
      final docRef = categoriesRef.doc(category.id);
      batch.set(docRef, category.toFirestore(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Future<void> _seedCategoriesRest() async {
    final batchOps = <BatchOperation>[];

    for (final category in Category.predefinedCategories) {
      batchOps.add(BatchOperation.set(
        'categories',
        category.id,
        category.toFirestore(),
      ));
    }

    await _restClient.batchWrite(batchOps);
  }

  /// Check if categories exist in Firestore
  Future<bool> categoriesExist() async {
    if (_useRest) {
      try {
        final docs = await _restClient.getCollection('categories', limit: 1);
        return docs.isNotEmpty;
      } catch (e) {
        debugPrint('categoriesExist REST error: $e');
        return false;
      }
    } else {
      final snapshot = await _firestore
          .collection('categories')
          .limit(1)
          .get();
      return snapshot.docs.isNotEmpty;
    }
  }

  /// Seed categories only if they don't exist
  Future<void> seedIfNeeded() async {
    try {
      final exists = await categoriesExist();
      if (!exists) {
        await seedCategories();
        debugPrint('CategorySeeder: Categories seeded successfully');
      } else {
        debugPrint('CategorySeeder: Categories already exist');
      }
    } catch (e) {
      debugPrint('CategorySeeder error: $e');
    }
  }
}
