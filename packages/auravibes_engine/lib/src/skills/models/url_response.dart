class UrlResponse {
  const UrlResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.elapsed,
  });

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
  final Duration elapsed;

  bool get isOk => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}
