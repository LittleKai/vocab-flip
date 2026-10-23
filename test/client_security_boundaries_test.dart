import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:vocabflip/core/web/sso_message.dart';
import 'package:vocabflip/data/services/google_drive_service.dart';

void main() {
  test('SSO rejects cross-origin, sibling, top-level and malformed messages',
      () {
    String? token(
            {Object? data = const {'type': 'AUTH_TOKEN', 'token': 'dummy'},
            String origin = 'https://shell.test',
            bool parent = true,
            bool framed = true}) =>
        trustedSsoToken(
            data: data,
            origin: origin,
            expectedOrigin: 'https://shell.test',
            fromParent: parent,
            framed: framed);
    expect(token(), 'dummy');
    expect(token(origin: 'https://evil.test'), isNull);
    expect(token(parent: false), isNull);
    expect(token(framed: false), isNull);
    expect(token(data: '{bad'), isNull);
    expect(token(data: {'type': 'AUTH_TOKEN', 'token': 123}), isNull);
    expect(token(data: {'type': 'AUTH_TOKEN', 'token': ''}), isNull);
  });

  test('native callback is bound to unique attempt and PKCE proof', () {
    final a = DesktopOAuthAttempt();
    final b = DesktopOAuthAttempt();
    expect(a.state, isNot(b.state));
    expect(a.verifier, isNot(b.verifier));
    expect(a.verifier, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(a.challenge, matches(RegExp(r'^[A-Za-z0-9_-]{43}$')));
    expect(a.challenge, isNot(a.verifier));
    expect(
        a.accepts(Uri(
            path: '/oauth2callback',
            queryParameters: {'state': a.state, 'code': 'dummy'})),
        isTrue);
    expect(
        a.accepts(Uri(
            path: '/oauth2callback',
            queryParameters: {'state': b.state, 'code': 'dummy'})),
        isFalse);
    expect(
        a.accepts(
            Uri(path: '/oauth2callback', queryParameters: {'code': 'dummy'})),
        isFalse);
    expect(
        a.accepts(Uri(
            path: '/', queryParameters: {'state': a.state, 'code': 'dummy'})),
        isFalse);
  });

  test('only explicit public configuration can enter client bundle', () {
    const allowed = {
      'API_URL',
      'GOOGLE_OAUTH_CLIENT_ID',
      'CLOUDINARY_CLOUD_NAMES',
      'CLOUDINARY_UPLOAD_PRESETS'
    };
    final names = File('assets/config.env')
        .readAsLinesSync()
        .where((line) =>
            line.trim().isNotEmpty && !line.trimLeft().startsWith('#'))
        .map((line) => line.split('=').first.trim());
    expect(names.every(allowed.contains), isTrue);
    final manifest = File('pubspec.yaml').readAsStringSync();
    expect(manifest, contains('- assets/config.env'));
    expect(RegExp(r'^\s*-\s*\.env\s*$', multiLine: true).hasMatch(manifest),
        isFalse);
  });
}
