// ignore_for_file: no-magic-number
// Required: Existing thresholds and limits use numeric values.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_response.freezed.dart';

@freezed
abstract class UrlResponse with _$UrlResponse {
  const factory UrlResponse({
    required int statusCode,
    required String body,
    required Map<String, List<String>> headers,
    required Duration elapsed,
  }) = _UrlResponse;

  const UrlResponse._();

  bool get isOk => statusCode >= 200 && statusCode < 300;
  bool get isRedirect => statusCode >= 300 && statusCode < 400;
  bool get isClientError => statusCode >= 400 && statusCode < 500;
  bool get isServerError => statusCode >= 500;
}
