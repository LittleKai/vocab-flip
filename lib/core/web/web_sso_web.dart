// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';
import 'package:flutter/foundation.dart';

const _vocabTokenKey = 'vocabflip_auth_token';

void setupWebSsoListener({required Function(String token) onTokenReceived}) {
  debugPrint('Initializing Web SSO Listener...');

  html.window.addEventListener('message', (html.Event event) {
    if (event is html.MessageEvent) {
      final data = event.data;

      final parsedData = _parseSsoMessage(data);
      if (parsedData == null) return;

      if (parsedData['type'] == 'AUTH_TOKEN' && parsedData['token'] != null) {
        final String token = parsedData['token'].toString();
        debugPrint('Web SSO Event received token.');
        onTokenReceived(token);
      }
    }
  });

  final storedToken = getStoredWebSsoToken();
  if (storedToken != null && storedToken.isNotEmpty) {
    debugPrint('Web SSO found token in localStorage.');
    onTokenReceived(storedToken);
  }

  html.window.parent?.postMessage({'type': 'AUTH_READY'}, '*');
}

String? getStoredWebSsoToken() {
  return html.window.localStorage[_vocabTokenKey];
}

void persistWebSsoToken(String token) {
  html.window.localStorage[_vocabTokenKey] = token;
}

void clearStoredWebSsoToken() {
  html.window.localStorage.remove(_vocabTokenKey);
}

String? getWebBaseUrl() {
  final hostname = html.window.location.hostname;
  debugPrint('Web SSO: checking hostname: $hostname');
  if (hostname == 'localhost' || hostname == '127.0.0.1') {
    return 'http://localhost:3001/api';
  }
  return null;
}

Map<String, dynamic>? _parseSsoMessage(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }

  if (data is String) {
    final trimmed = data.trimLeft();
    if (!trimmed.startsWith('{')) return null;

    try {
      final decoded = jsonDecode(trimmed);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {
      return null;
    }
  }

  return null;
}
