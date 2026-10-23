import 'package:flutter/foundation.dart';

void Function() setupWebSsoListener(
    {required Function(String token) onTokenReceived}) {
  debugPrint('Web SSO only supported on Web platform.');
  return () {};
}

String? getStoredWebSsoToken() => null;

void persistWebSsoToken(String token) {}

void clearStoredWebSsoToken({String? departingToken}) {}

String? getWebBaseUrl() => null;
