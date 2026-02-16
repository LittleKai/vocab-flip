import 'dart:io' show Platform;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/feedback_item.dart';
import '../remote/firebase/firebase_service.dart';
import '../remote/firebase/firestore_rest_client.dart';
import '../../core/constants/app_constants.dart';

class FeedbackRepository {
  final FirebaseService _firebaseService = FirebaseService();
  final FirestoreRestClient _restClient = FirestoreRestClient();

  bool get _useRest => FirestoreRestClient.shouldUseRest;

  CollectionReference<Map<String, dynamic>> get _feedbackRef =>
      FirebaseFirestore.instance.collection(AppConstants.collectionFeedback);

  Future<void> submitFeedback({
    required String category,
    required String message,
    String? email,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final payload = <String, dynamic>{
      'category': category,
      'message': message,
      if (email != null && email.isNotEmpty) 'email': email,
      'app_version': packageInfo.version,
      'platform': _getPlatform(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (_firebaseService.userId != null)
        'user_id': _firebaseService.userId!,
    };

    if (_useRest) {
      final result = await _restClient.createDocument(
        AppConstants.collectionFeedback,
        payload,
      );
      if (result == null) {
        throw Exception('Failed to submit feedback');
      }
    } else {
      await _feedbackRef.add(payload);
    }
  }

  Future<List<FeedbackItem>> getFeedbackList({int limit = 50}) async {
    if (_useRest) {
      final docs = await _restClient.getCollection(
        AppConstants.collectionFeedback,
        orderBy: [OrderBy('created_at', descending: true)],
        limit: limit,
        requireAuth: true,
      );
      return docs.map((doc) => FeedbackItem.fromMap(doc)).toList();
    } else {
      final snapshot = await _feedbackRef
          .orderBy('created_at', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return FeedbackItem.fromMap(data);
      }).toList();
    }
  }

  Future<int> getFeedbackCountSince(DateTime since) async {
    final sinceStr = since.toUtc().toIso8601String();

    if (_useRest) {
      final docs = await _restClient.getCollection(
        AppConstants.collectionFeedback,
        where: [
          QueryFilter(
            'created_at',
            FilterOperator.greaterThan,
            sinceStr,
          ),
        ],
        orderBy: [OrderBy('created_at', descending: true)],
        requireAuth: true,
      );
      return docs.length;
    } else {
      final snapshot = await _feedbackRef
          .where('created_at', isGreaterThan: sinceStr)
          .orderBy('created_at', descending: true)
          .get();
      return snapshot.docs.length;
    }
  }

  String _getPlatform() {
    if (kIsWeb) return 'web';
    if (Platform.isWindows) return 'windows';
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
  }
}
