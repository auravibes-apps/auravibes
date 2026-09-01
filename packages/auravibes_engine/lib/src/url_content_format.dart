enum UrlContentFormat {
  markdown,
  text,
  json,
  html,
  unsupported;

  String get label => switch (this) {
    markdown => 'markdown',
    text => 'text',
    json => 'json',
    html => 'html',
    unsupported => 'unsupported',
  };
}

class const TransformedUrlContent({
  required final String body,
  required final UrlContentFormat format,
  required final int originalLength,
  required final bool truncated,
  required final Duration elapsed,
  final String? contentType,
});
