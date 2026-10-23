import 'dart:convert';

String? trustedSsoToken(
    {required Object? data,
    required String origin,
    required String expectedOrigin,
    required bool fromParent,
    required bool framed}) {
  if (!framed || !fromParent || origin != expectedOrigin) return null;
  try {
    final parsed = data is String ? jsonDecode(data) : data;
    if (parsed is! Map || parsed['type'] != 'AUTH_TOKEN') return null;
    final token = parsed['token'];
    return token is String && token.isNotEmpty ? token : null;
  } catch (_) {
    return null;
  }
}
