import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_response.freezed.dart';
part 'url_response.g.dart';

@freezed
abstract class UrlResponse with _$UrlResponse {
  const factory UrlResponse({
    required int statusCode,
    required String body,
    required Map<String, String> headers,
    required Duration elapsed,
  }) = _UrlResponse;

  factory UrlResponse.fromJson(Map<String, dynamic> json) =>
      _$UrlResponseFromJson(json);

  const UrlResponse._();

  bool get isOk => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}
