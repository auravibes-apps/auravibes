class AppSkillUrlResponse {
  const AppSkillUrlResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
    required this.elapsed,
  });

  final int statusCode;
  final String body;
  final Map<String, List<String>> headers;
  final Duration elapsed;
}
