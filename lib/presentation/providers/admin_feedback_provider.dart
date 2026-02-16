import 'package:flutter/foundation.dart';
import '../../data/models/feedback_item.dart';
import '../../data/repositories/feedback_repository.dart';
import '../../data/local/preferences/app_preferences.dart';

class AdminFeedbackProvider extends ChangeNotifier {
  final AppPreferences _preferences;
  final FeedbackRepository _repository = FeedbackRepository();

  List<FeedbackItem> _feedbackList = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  String? _error;

  List<FeedbackItem> get feedbackList => _feedbackList;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;
  String? get error => _error;

  AdminFeedbackProvider({required AppPreferences preferences})
      : _preferences = preferences {
    Future.microtask(() => loadUnreadCount());
  }

  Future<void> loadUnreadCount() async {
    try {
      final lastReadAt = _preferences.adminFeedbackLastReadAt;
      _unreadCount = await _repository.getFeedbackCountSince(
        lastReadAt ?? DateTime.utc(2000),
      );
      notifyListeners();
    } catch (e) {
      debugPrint('AdminFeedbackProvider.loadUnreadCount error: $e');
    }
  }

  Future<void> loadFeedback() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _feedbackList = await _repository.getFeedbackList();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> markAllRead() async {
    await _preferences.setAdminFeedbackLastReadAt(DateTime.now().toUtc());
    _unreadCount = 0;
    notifyListeners();
  }
}
