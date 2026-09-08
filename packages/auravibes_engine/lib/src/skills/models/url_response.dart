class const UrlResponse({
  required final int statusCode,
  required final String body,
  required final Map<String, List<String>> headers,
  required final Duration elapsed,
}) {
  bool get isOk => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}
