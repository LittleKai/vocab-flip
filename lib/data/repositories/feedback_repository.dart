import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../api/api_client.dart';
import '../auth/alpha_auth_session.dart';
import '../models/feedback_item.dart';
import '../remote/mongo/vocab_api_helpers.dart';

class FeedbackRepository {
  final ApiClient _apiClient = ApiClient();
  final AlphaAuthSession _authSession = AlphaAuthSession();

  Future<void> submitFeedback({
    required String category,
    required String message,
    String? email,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    await _apiClient.dio.post('/vocab/feedback', data: {
      'category': category,
      'message': message,
      if (email != null && email.isNotEmpty) 'email': email,
      'app_version': packageInfo.version,
      'platform': _getPlatform(),
      'created_at': DateTime.now().toUtc().toIso8601String(),
      if (_authSession.userId != null) 'user_id': _authSession.userId,
    });
  }

  Future<List<FeedbackItem>> getFeedbackList({int limit = 50}) async {
    final response = await _apiClient.dio.get(
      '/vocab/feedback',
      queryParameters: {'limit': limit},
    );
    return unwrapApiList(response.data).map(FeedbackItem.fromMap).toList();
  }

  Future<int> getFeedbackCountSince(DateTime since) async {
    final response = await _apiClient.dio.get(
      '/vocab/feedback/count',
      queryParameters: {'since': since.toUtc().toIso8601String()},
    );
    final data = unwrapApiMap(response.data);
    return data?['count'] as int? ?? 0;
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
