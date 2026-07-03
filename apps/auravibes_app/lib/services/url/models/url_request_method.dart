// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_skills/auravibes_skills.dart'
    show UrlRequestMethod, UrlResponseFormat;
import 'package:freezed_annotation/freezed_annotation.dart';

export 'package:auravibes_skills/auravibes_skills.dart'
    show UrlRequestMethod, UrlResponseFormat;

part 'url_request_method.freezed.dart';

@freezed
abstract class UrlRequest with _$UrlRequest {
  const factory UrlRequest({
    required String url,
    @Default(UrlRequestMethod.get) UrlRequestMethod method,
    @Default({}) Map<String, String> headers,
    String? body,
    @Default(Duration(seconds: 30)) Duration timeout,
    @Default(UrlResponseFormat.defaultFormat) UrlResponseFormat format,
  }) = _UrlRequest;
}
