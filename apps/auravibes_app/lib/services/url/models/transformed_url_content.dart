enum UrlContentFormat {
  markdown,
  text,
  json,
  html,
  unsupported
  ;

  String get label => switch (this) {
    markdown => 'markdown',
    text => 'text',
    json => 'json',
    html => 'html',
    unsupported => 'unsupported',
  };
}

class TransformedUrlContent {
  const TransformedUrlContent({
    required this.body,
    required this.format,
    required this.originalLength,
    required this.truncated,
    this.contentType,
  });

  final String body;
  final UrlContentFormat format;
  final String? contentType;
  final int originalLength;
  final bool truncated;
}
