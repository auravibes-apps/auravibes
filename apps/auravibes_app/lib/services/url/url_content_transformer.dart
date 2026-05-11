// ignore_for_file: cascade_invocations
// StringBuffer.write returns void, making cascades meaningless.
// The _processTable method's for-loop bodies separate consecutive
// buffer calls where cascading across control flow is misleading.

import 'package:auravibes_app/services/url/models/transformed_url_content.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as parser;

class UrlContentTransformer {
  const UrlContentTransformer();

  static const int maxOutputLength = 1024 * 1024;
  static const _truncationSuffix = '\n... [truncated]';

  static final Set<String> _blockTags = {
    'div',
    'section',
    'article',
    'main',
    'header',
    'footer',
    'aside',
    'p',
    'h1',
    'h2',
    'h3',
    'h4',
    'h5',
    'h6',
    'pre',
    'blockquote',
    'figure',
    'figcaption',
    'details',
    'summary',
    'fieldset',
    'form',
  };

  static final Set<String> _stripTags = {
    'script',
    'style',
    'noscript',
    'iframe',
    'object',
    'embed',
    'svg',
    'canvas',
    'applet',
    'map',
    'area',
  };

  static final Set<String> _skipContentTags = {
    'nav',
  };

  TransformedUrlContent transform(
    UrlResponse response, {
    UrlResponseFormat requestedFormat = UrlResponseFormat.defaultFormat,
  }) {
    final contentType = _extractContentType(response.headers);
    final body = response.body;
    final originalLength = body.length;
    final elapsed = response.elapsed;

    final effectiveFormat = requestedFormat == UrlResponseFormat.defaultFormat
        ? UrlResponseFormat.markdown
        : requestedFormat;

    if (contentType == null) {
      return _passthrough(
        body,
        originalLength,
        elapsed,
        contentType,
        UrlContentFormat.unsupported,
      );
    }

    if (contentType.contains('text/html')) {
      return switch (effectiveFormat) {
        UrlResponseFormat.html => _passthrough(
          body,
          originalLength,
          elapsed,
          contentType,
          UrlContentFormat.html,
        ),
        UrlResponseFormat.text => _transformHtmlToText(
          body,
          originalLength,
          elapsed,
          contentType,
        ),
        _ => _transformHtml(body, originalLength, elapsed, contentType),
      };
    }

    final isJson =
        contentType == 'application/json' || contentType.endsWith('+json');
    if (isJson) {
      return _passthrough(
        body,
        originalLength,
        elapsed,
        contentType,
        UrlContentFormat.json,
      );
    }

    if (contentType.contains('text/markdown') ||
        contentType.contains('text/x-markdown')) {
      return _passthrough(
        body,
        originalLength,
        elapsed,
        contentType,
        UrlContentFormat.markdown,
      );
    }

    if (contentType.contains('text/plain')) {
      return _passthrough(
        body,
        originalLength,
        elapsed,
        contentType,
        UrlContentFormat.text,
      );
    }

    return _passthrough(
      body,
      originalLength,
      elapsed,
      contentType,
      UrlContentFormat.unsupported,
    );
  }

  TransformedUrlContent _transformHtml(
    String body,
    int originalLength,
    Duration elapsed,
    String contentType,
  ) {
    final document = parser.parse(body);

    _stripUnwantedElements(document);

    final titleElement = document.querySelector('title');
    final title = titleElement?.text.trim();

    final bodyElement = document.body;
    if (bodyElement == null) {
      final text = document.text?.trim() ?? '';
      final escaped = _escapeMarkdownText(text);
      final (output, truncated) = _truncateIfNeeded(escaped, originalLength);
      return TransformedUrlContent(
        body: output,
        format: .markdown,
        contentType: contentType,
        originalLength: originalLength,
        truncated: truncated,
        elapsed: elapsed,
      );
    }

    final buffer = StringBuffer();
    final firstH1 = bodyElement.querySelector('h1');
    final titleMatchesH1 = firstH1 != null && firstH1.text.trim() == title?.trim();
    if (title != null && title.isNotEmpty && !titleMatchesH1) {
      buffer
        ..writeln('# $title')
        ..writeln();
    }

    _processChildren(bodyElement, buffer, 0);

    var markdown = buffer.toString().trim();

    markdown = _collapseBlankLines(markdown);

    final (output, truncated) = _truncateIfNeeded(markdown, originalLength);

    return TransformedUrlContent(
      body: output,
      format: .markdown,
      contentType: contentType,
      originalLength: originalLength,
      truncated: truncated,
      elapsed: elapsed,
    );
  }

  TransformedUrlContent _transformHtmlToText(
    String body,
    int originalLength,
    Duration elapsed,
    String contentType,
  ) {
    final document = parser.parse(body);

    _stripUnwantedElements(document);

    final bodyElement = document.body;
    final text = bodyElement?.text ?? document.text ?? '';

    final cleaned = text
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();

    final (output, truncated) = _truncateIfNeeded(cleaned, originalLength);

    return TransformedUrlContent(
      body: output,
      format: .text,
      contentType: contentType,
      originalLength: originalLength,
      truncated: truncated,
      elapsed: elapsed,
    );
  }

  void _stripUnwantedElements(dom.Document document) {
    for (final tag in _stripTags) {
      for (final element in document.querySelectorAll(tag)) {
        element.remove();
      }
    }
  }

  void _processChildren(dom.Element parent, StringBuffer buffer, int depth) {
    for (final node in parent.nodes) {
      if (node is dom.Text) {
        _processTextNode(node, buffer);
      } else if (node is dom.Element) {
        _processElementNode(node, buffer, depth);
      }
    }
  }

  void _processInlineChildren(dom.Element parent, StringBuffer buffer) {
    for (final node in parent.nodes) {
      if (node is dom.Text) {
        _processTextNode(node, buffer);
      } else if (node is dom.Element) {
        _processElementNode(node, buffer, 0);
      }
    }
  }

  void _processTextNode(dom.Text textNode, StringBuffer buffer) {
    final text = _escapeMarkdownText(textNode.text);
    if (text.isNotEmpty) {
      buffer.write(text);
    }
  }

  String _escapeMarkdownText(String text) {
    return text
        .replaceAll(r'\', r'\\')
        .replaceAll('`', r'\`')
        .replaceAll('*', r'\*')
        .replaceAll('_', r'\_')
        .replaceAll('[', r'\[')
        .replaceAll(']', r'\]')
        .replaceAll('<', r'\<')
        .replaceAll('|', r'\|')
        .replaceAll('~', r'\~');
  }

  String _escapeCodeContent(String text) {
    if (!text.contains('`')) return '`$text`';
    var maxRun = 0;
    var run = 0;
    for (var i = 0; i < text.length; i++) {
      if (text[i] == '`') {
        run++;
        if (run > maxRun) maxRun = run;
      } else {
        run = 0;
      }
    }
    final fence = '`' * (maxRun + 1);
    return '$fence $text $fence';
  }

  void _processElementNode(
    dom.Element element,
    StringBuffer buffer,
    int depth,
  ) {
    final tag = element.localName?.toLowerCase() ?? '';

    if (_stripTags.contains(tag)) {
      return;
    }

    if (_skipContentTags.contains(tag)) {
      return;
    }

    switch (tag) {
      case 'br':
      case 'hr':
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
      case 'p':
      case 'li':
        _processTextBlockElement(element, buffer, depth, tag);
        return;
      case 'a':
        _processAnchor(element, buffer);
        return;
      case 'strong':
      case 'b':
        _processBold(element, buffer);
        return;
      case 'em':
      case 'i':
        _processItalic(element, buffer);
        return;
      case 'code':
        _processInlineCode(element, buffer);
        return;
      case 'pre':
        _processPreElement(element, buffer);
        return;
      case 'blockquote':
        _processBlockquote(element, buffer);
        return;
      case 'img':
        final alt = element.attributes['alt'] ?? '';
        final src = element.attributes['src'] ?? '';
        if (alt.isNotEmpty || src.isNotEmpty) {
          _ensureNewline(buffer);
          buffer.writeln('![$alt]($src)');
        }
        return;
      case 'ul':
      case 'ol':
        _ensureNewline(buffer);
        _processChildren(element, buffer, depth + 1);
        _ensureNewline(buffer);
        return;
      case 'table':
        _ensureNewline(buffer);
        _processTable(element, buffer);
        _ensureNewline(buffer);
        return;
      case 'thead':
      case 'tbody':
      case 'tfoot':
        _processChildren(element, buffer, depth);
        return;
      case 'tr':
      case 'th':
      case 'td':
        return;
      default:
        if (_isBlockTag(tag)) {
          _ensureNewline(buffer);
          _processChildren(element, buffer, depth + 1);
          _ensureNewline(buffer);
        } else {
          _processChildren(element, buffer, depth);
        }
    }
  }

  void _processPreElement(dom.Element element, StringBuffer buffer) {
    _ensureNewline(buffer);
    buffer.writeln('```');

    final codeElement = element.querySelector('code');
    final text = codeElement?.text ?? element.text;

    if (text.isNotEmpty) {
      buffer.writeln(text.trimRight());
    }

    buffer.writeln('```');
    _ensureNewline(buffer);
  }

  void _processBlockquote(
    dom.Element element,
    StringBuffer buffer,
  ) {
    _ensureNewline(buffer);

    final inlineBuffer = StringBuffer();
    _processInlineChildren(element, inlineBuffer);
    final text = inlineBuffer.toString().trim();
    if (text.isNotEmpty) {
      for (final line in text.split('\n')) {
        buffer.writeln('> $line');
      }
    }

    _ensureNewline(buffer);
  }

  void _processTable(dom.Element table, StringBuffer buffer) {
    final rows = <List<String>>[];
    for (final tr in table.querySelectorAll('tr')) {
      final cells = <String>[];
      for (final cell in tr.querySelectorAll('th, td')) {
        cells.add(
          cell.text.trim().replaceAll('\n', ' ').replaceAll('|', r'\|'),
        );
      }
      if (cells.isNotEmpty) rows.add(cells);
    }

    if (rows.isEmpty) return;

    var colCount = 0;
    for (final row in rows) {
      if (row.length > colCount) colCount = row.length;
    }

    _writeTableRow(rows[0], colCount, buffer);

    buffer.write('| ');
    for (var i = 0; i < colCount; i++) {
      buffer.write('--- | ');
    }
    buffer.writeln();

    for (var i = 1; i < rows.length; i++) {
      _writeTableRow(rows[i], colCount, buffer);
    }
  }

  bool _isBlockTag(String tag) {
    return _blockTags.contains(tag);
  }

  bool _isInsideOrderedList(dom.Element element) {
    var parent = element.parent;
    while (parent != null) {
      if (parent.localName?.toLowerCase() == 'ol') return true;
      if (parent.localName?.toLowerCase() == 'ul') return false;
      parent = parent.parent;
    }
    return false;
  }

  bool _isPreChild(dom.Element element) {
    var parent = element.parent;
    while (parent != null) {
      if (parent.localName?.toLowerCase() == 'pre') return true;
      parent = parent.parent;
    }
    return false;
  }

  void _ensureNewline(StringBuffer buffer) {
    final length = buffer.length;
    if (length == 0) return;
    if (length >= 2 && buffer.toString().endsWith('\n\n')) return;
    buffer.writeln();
  }

  void _processAnchor(dom.Element element, StringBuffer buffer) {
    final href = element.attributes['href'];
    final inlineBuffer = StringBuffer();
    _processInlineChildren(element, inlineBuffer);
    final text = inlineBuffer.toString().trim();
    if (text.isEmpty) return;
    if (href != null && href.isNotEmpty) {
      buffer.write('[$text]($href)');
    } else {
      buffer.write(text);
    }
  }

  void _processBold(dom.Element element, StringBuffer buffer) {
    final inlineBuffer = StringBuffer();
    _processInlineChildren(element, inlineBuffer);
    final text = inlineBuffer.toString().trim();
    if (text.isNotEmpty) {
      buffer.write('**$text**');
    }
  }

  void _processItalic(dom.Element element, StringBuffer buffer) {
    final inlineBuffer = StringBuffer();
    _processInlineChildren(element, inlineBuffer);
    final text = inlineBuffer.toString().trim();
    if (text.isNotEmpty) {
      buffer.write('*$text*');
    }
  }

  void _processInlineCode(dom.Element element, StringBuffer buffer) {
    if (_isPreChild(element)) return;
    final text = element.text.trim();
    if (text.isNotEmpty) {
      buffer.write(_escapeCodeContent(text));
    }
  }

  void _processTextBlockElement(
    dom.Element element,
    StringBuffer buffer,
    int depth,
    String tag,
  ) {
    switch (tag) {
      case 'br':
        buffer.writeln();
        return;
      case 'hr':
        buffer.writeln();
        buffer.writeln('---');
        buffer.writeln();
        return;
      case 'h1':
      case 'h2':
      case 'h3':
      case 'h4':
      case 'h5':
      case 'h6':
        final level = int.parse(tag.substring(1));
        final inlineBuffer = StringBuffer();
        _processInlineChildren(element, inlineBuffer);
        final text = inlineBuffer.toString().trim();
        if (text.isNotEmpty) {
          _ensureNewline(buffer);
          buffer.writeln('${'#' * level} $text');
          _ensureNewline(buffer);
        }
        return;
      case 'p':
        final inlineBuffer = StringBuffer();
        _processInlineChildren(element, inlineBuffer);
        final text = inlineBuffer.toString().trim();
        if (text.isNotEmpty) {
          _ensureNewline(buffer);
          buffer.writeln(text);
        }
        return;
      case 'li':
        _ensureNewline(buffer);
        final indent = '  ' * (depth > 0 ? depth - 1 : 0);
        final isOrdered = _isInsideOrderedList(element);
        final String marker;
        if (isOrdered) {
          var index = 1;
          for (final sibling in element.parent?.children ?? []) {
            if (identical(sibling, element)) break;
            if (sibling.localName?.toLowerCase() == 'li') index++;
          }
          marker = '$index. ';
        } else {
          marker = '- ';
        }
        buffer.write('$indent$marker');
        _processChildren(element, buffer, depth);
    }
  }

  void _writeTableRow(List<String> cells, int colCount, StringBuffer buffer) {
    buffer.write('| ');
    for (var i = 0; i < colCount; i++) {
      buffer.write(i < cells.length ? cells[i] : '');
      buffer.write(' | ');
    }
    buffer.writeln();
  }

  String _collapseBlankLines(String markdown) {
    return markdown.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  }

  TransformedUrlContent _passthrough(
    String body,
    int originalLength,
    Duration elapsed,
    String? contentType,
    UrlContentFormat format,
  ) {
    if (body.isEmpty) {
      return TransformedUrlContent(
        body: body,
        format: format,
        contentType: contentType,
        originalLength: originalLength,
        truncated: false,
        elapsed: elapsed,
      );
    }

    final (output, truncated) = _truncateIfNeeded(body, originalLength);

    return TransformedUrlContent(
      body: output,
      format: format,
      contentType: contentType,
      originalLength: originalLength,
      truncated: truncated,
      elapsed: elapsed,
    );
  }

  (String, bool) _truncateIfNeeded(String body, int originalLength) {
    if (body.length <= maxOutputLength) {
      return (body, false);
    }
    return (
      '${body.substring(0, maxOutputLength - _truncationSuffix.length)}'
          '$_truncationSuffix',
      true,
    );
  }

  String? _extractContentType(Map<String, List<String>> headers) {
    for (final entry in headers.entries) {
      if (entry.key.toLowerCase() == 'content-type') {
        final values = entry.value;
        if (values.isNotEmpty) {
          return values.first.split(';').first.trim().toLowerCase();
        }
      }
    }
    return null;
  }
}
