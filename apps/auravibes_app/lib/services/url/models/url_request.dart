import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_request.freezed.dart';

enum UrlRequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD')
  ;

  const UrlRequestMethod(this.value);
  final String value;
}

@freezed
abstract class UrlRequest with _$UrlRequest {
  const factory UrlRequest({
    required String url,
    @Default(UrlRequestMethod.get) UrlRequestMethod method,
    Map<String, String>? headers,
    String? body,
    @Default(Duration(seconds: 30)) Duration timeout,
  }) = _UrlRequest;
}
