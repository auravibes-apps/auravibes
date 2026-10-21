enum UrlResponseFormat(final String label) {
  defaultFormat(''),
  markdown('markdown'),
  text('text'),
  html('html');

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
      (format) => format.label == normalized,
      orElse: () => throw FormatException(
        'Unsupported format: $value. '
        'Supported formats: markdown, text, html.',
      ),
    );
  }
}
