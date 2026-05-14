import 'package:freezed_annotation/freezed_annotation.dart';

part 'url_request.freezed.dart';

enum UrlRequestMethod {
  get('GET'),
  post('POST'),
  put('PUT'),
  delete('DELETE'),
  patch('PATCH'),
  head('HEAD');

  const UrlRequestMethod(this.value);
  final String value;
}

enum UrlResponseFormat {
  defaultFormat(''),
  markdown('markdown'),
  text('text'),
  html('html');

  const UrlResponseFormat(this.label);
  final String label;

  String get acceptHeader => switch (this) {
    .html =>
      'text/html;q=1.0, application/xhtml+xml;q=0.9, '
          'text/plain;q=0.8, text/markdown;q=0.7, */*;q=0.1',
    .text =>
      'text/plain;q=1.0, text/markdown;q=0.9, '
          'text/html;q=0.8, */*;q=0.1',
    _ =>
      'text/markdown;q=1.0, text/x-markdown;q=0.9, '
          'text/plain;q=0.8, text/html;q=0.7, */*;q=0.1',
  };

  static UrlResponseFormat fromString(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.isEmpty) return .defaultFormat;
    return values.firstWhere(
      (f) => f.label == normalized,
      orElse: () => throw FormatException(
        'Unsupported format: $value. '
        'Supported formats: markdown, text, html.',
      ),
    );
  }
}

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
