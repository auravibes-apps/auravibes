import 'package:auravibes_engine/src/skills/models/url_request_method.dart';
import 'package:auravibes_engine/src/skills/models/url_response_format.dart';

class const UrlRequest({
  required final String url,
  final UrlRequestMethod method = UrlRequestMethod.get,
  final Map<String, String> headers = const {},
  final String? body,
  final Duration timeout = const Duration(seconds: 30),
  final UrlResponseFormat format = UrlResponseFormat.defaultFormat,
});
