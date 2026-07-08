import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
import 'package:auravibes_engine/src/skills/models/url_response_format.dart';

class AppSkillUrlRequest {
  const AppSkillUrlRequest({
    required this.url,
    this.method = UrlRequestMethod.get,
    this.headers = const {},
    this.body,
    this.timeout = const Duration(seconds: 30),
    this.format = UrlResponseFormat.defaultFormat,
  });

  final String url;
  final UrlRequestMethod method;
  final Map<String, String> headers;
  final String? body;
  final Duration timeout;
  final UrlResponseFormat format;
}
