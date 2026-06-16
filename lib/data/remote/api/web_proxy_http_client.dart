import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../api/api_client.dart';

/// A custom HTTP client for the Web platform that proxies requests to whitelisted
/// third-party dictionary domains through our backend to bypass CORS constraints.
class WebProxyHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    // Only proxy on Web for specific third-party dictionary APIs
    if (kIsWeb) {
      final host = request.url.host;
      if (host == 'dict.laban.vn' ||
          host == 'mazii.net' ||
          host == 'jisho.org' ||
          host == 'api.dictionaryapi.dev') {
        try {
          final apiClient = ApiClient();
          final proxyUrl = '${apiClient.dio.options.baseUrl}/vocab/dictionary/proxy';
          debugPrint('[WebProxyHttpClient] Proxying ${request.method} ${request.url} via $proxyUrl');

          // Read body if it exists
          String? requestBody;
          if (request is http.Request && request.body.isNotEmpty) {
            requestBody = request.body;
          }

          // Construct a POST request to our backend proxy endpoint
          final proxyRequest = http.Request('POST', Uri.parse(proxyUrl));
          proxyRequest.headers['Content-Type'] = 'application/json';
          proxyRequest.headers['Accept'] = '*/*';

          // Attach auth token if available to authenticate the user request
          final token = await apiClient.getToken();
          if (token != null) {
            proxyRequest.headers['Authorization'] = 'Bearer $token';
          }

          proxyRequest.body = jsonEncode({
            'url': request.url.toString(),
            'method': request.method,
            'headers': request.headers,
            'data': requestBody,
          });

          return await _inner.send(proxyRequest);
        } catch (e) {
          debugPrint('[WebProxyHttpClient] Error proxying request: $e. Falling back to direct client.');
        }
      }
    }

    return _inner.send(request);
  }
}
