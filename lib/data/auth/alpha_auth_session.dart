class AlphaAuthSession {
  static final AlphaAuthSession _instance = AlphaAuthSession._internal();
  factory AlphaAuthSession() => _instance;
  AlphaAuthSession._internal();

  String? _userId;
  String? _email;
  String? _displayName;

  String? get userId => _userId;
  String? get email => _email;
  String? get displayName => _displayName;
  bool get isAuthenticated => _userId != null && _userId!.isNotEmpty;

  void setUser({
    required String userId,
    String? email,
    String? displayName,
  }) {
    _userId = userId.isNotEmpty ? userId : email;
    _email = email;
    _displayName = displayName;
  }

  void clear() {
    _userId = null;
    _email = null;
    _displayName = null;
  }
}
