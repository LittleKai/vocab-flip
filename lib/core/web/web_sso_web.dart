// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'sso_message.dart';

const _vocabTokenKey = 'vocabflip_auth_token';

void Function() setupWebSsoListener(
    {required Function(String token) onTokenReceived}) {
  final subscription = html.window.onMessage.listen((event) {
    final token = trustedSsoToken(
        data: event.data,
        origin: event.origin,
        expectedOrigin: html.window.location.origin,
        fromParent: event.source == html.window.parent,
        framed: html.window.parent != html.window);
    if (token != null) onTokenReceived(token);
  });

  if (html.window.parent != html.window) {
    html.window.parent
        ?.postMessage({'type': 'AUTH_READY'}, html.window.location.origin);
  }
  return () {
    subscription.cancel();
  };
}

String? getStoredWebSsoToken() {
  // Alpha Studio opens a same-origin tab and publishes this shell alias.
  return html.window.localStorage['alpha_studio_token'] ??
      html.window.localStorage[_vocabTokenKey];
}

void persistWebSsoToken(String token) {
  html.window.localStorage[_vocabTokenKey] = token;
}

void clearStoredWebSsoToken({String? departingToken}) {
  final token = departingToken ?? html.window.localStorage[_vocabTokenKey];
  if (token != null &&
      html.window.localStorage['alpha_studio_token'] == token) {
    html.window.localStorage.remove('alpha_studio_token');
  }
  html.window.localStorage.remove(_vocabTokenKey);
}

String? getWebBaseUrl() {
  final hostname = html.window.location.hostname;
  if (hostname == 'localhost' || hostname == '127.0.0.1') {
    return 'http://localhost:3001/api';
  }
  return null;
}
