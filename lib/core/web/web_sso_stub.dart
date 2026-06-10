import 'package:flutter/foundation.dart';

void setupWebSsoListener({required Function(String token) onTokenReceived}) {
  debugPrint('Web SSO only supported on Web platform.');
}

String? getStoredWebSsoToken() => null;

void persistWebSsoToken(String token) {}

void clearStoredWebSsoToken() {}

String? getWebBaseUrl() => null;
