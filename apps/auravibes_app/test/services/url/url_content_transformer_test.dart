import 'package:auravibes_app/services/url/models/transformed_url_content.dart';
import 'package:auravibes_app/services/url/models/url_request.dart';
import 'package:auravibes_app/services/url/models/url_response.dart';
import 'package:auravibes_app/services/url/url_content_transformer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UrlContentTransformer', () {
    const transformer = UrlContentTransformer();

    group('HTML transformation', () {
      test('converts heading tags to markdown headings', () {
        final response = _htmlResponse('<h1>Title</h1><p>Content here.</p>');
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('# Title'));
        expect(result.body, contains('Content here.'));
      });

      test('strips script and style tags', () {
        final response = _htmlResponse(
          '<html><head><script>alert("xss")</script><style>body { color: red; }</style></head><body><p>Safe content</p></body></html>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('Safe content'));
        expect(result.body, isNot(contains('alert')));
        expect(result.body, isNot(contains('color: red')));
      });

      test('converts links to markdown links', () {
        final response = _htmlResponse(
          '<p>Visit <a href="https://example.com">Example</a> site.</p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('[Example](https://example.com)'));
      });

      test('converts emphasis and strong tags', () {
        final response = _htmlResponse(
          '<p>This is <strong>bold</strong> and <em>italic</em> text.</p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('**bold**'));
        expect(result.body, contains('*italic*'));
      });

      test('converts unordered lists', () {
        final response = _htmlResponse(
          '<ul><li>Item 1</li><li>Item 2</li></ul>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('- Item 1'));
        expect(result.body, contains('- Item 2'));
      });

      test('converts ordered lists', () {
        final response = _htmlResponse(
          '<ol><li>First</li><li>Second</li></ol>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('1. First'));
        expect(result.body, contains('1. Second'));
      });

      test('converts blockquotes', () {
        final response = _htmlResponse(
          '<blockquote><p>Quoted text</p></blockquote>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('> Quoted text'));
      });

      test('converts code elements inline', () {
        final response = _htmlResponse(
          '<p>Use <code>print()</code> function.</p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('`print()`'));
      });

      test('converts pre elements to code blocks', () {
        final response = _htmlResponse(
          '<pre><code>const x = 1;\nprint(x);</code></pre>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('```'));
        expect(result.body, contains('const x = 1;'));
        expect(result.body, contains('print(x);'));
      });

      test('extracts title as h1', () {
        final response = _htmlResponse(
          '<html><head><title>Page Title</title></head><body><p>Content</p></body></html>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('# Page Title'));
      });

      test('handles images with alt text', () {
        final response = _htmlResponse(
          '<p>Here is an image: <img src="photo.jpg" alt="A photo"></p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('![A photo](photo.jpg)'));
      });

      test('handles horizontal rules', () {
        final response = _htmlResponse(
          '<p>Above</p><hr><p>Below</p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('---'));
      });

      test('strips svg elements', () {
        final response = _htmlResponse(
          '<p>Text</p><svg><circle cx="50" cy="50" r="40"/></svg><p>More</p>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('Text'));
        expect(result.body, contains('More'));
        expect(result.body, isNot(contains('circle')));
      });

      test('handles deeply nested content', () {
        final response = _htmlResponse(
          '<div><section><article><p>Nested paragraph</p></article></section></div>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('Nested paragraph'));
      });

      test('returns empty body for empty HTML', () {
        final response = _htmlResponse('');
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, isEmpty);
      });
    });

    group('JSON transformation', () {
      test('preserves JSON content as-is', () {
        final response = _jsonResponse('{"key": "value"}');
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.json);
        expect(result.body, '{"key": "value"}');
        expect(result.truncated, isFalse);
      });
    });

    group('Plain text transformation', () {
      test('preserves plain text as-is', () {
        final response = _plainTextResponse('Hello world');
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.text);
        expect(result.body, 'Hello world');
      });
    });

    group('Unknown content type', () {
      test('preserves content with unsupported format', () {
        final response = _responseWithContentType(
          'binary data',
          'application/octet-stream',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.unsupported);
        expect(result.body, 'binary data');
      });
    });

    group('Missing content type', () {
      test('preserves content when no content-type header', () {
        final response = _responseWithContentType('some text', null);
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.unsupported);
        expect(result.body, 'some text');
      });
    });

    group('Truncation', () {
      test('truncates content exceeding max length', () {
        const leading = 'Start ';
        final padding = 'x' * (UrlContentTransformer.maxOutputLength + 100);
        final response = _plainTextResponse('$leading$padding');
        final result = transformer.transform(response);

        expect(result.truncated, isTrue);
        expect(result.body, contains('[truncated]'));
        expect(result.body.startsWith(leading), isTrue);
        expect(result.originalLength, greaterThan(result.body.length));
      });

      test('does not truncate content within max length', () {
        final response = _plainTextResponse('Short content');
        final result = transformer.transform(response);

        expect(result.truncated, isFalse);
      });
    });

    group('Requested format', () {
      test(
        'default format maps HTML to markdown',
        () {
          final response = _htmlResponse('<h1>Hello</h1>');
          final result = transformer.transform(response);

          expect(result.format, UrlContentFormat.markdown);
          expect(result.body, contains('# Hello'));
        },
      );

      test(
        'markdown format maps HTML to markdown',
        () {
          final response = _htmlResponse('<h1>Hello</h1>');
          final result = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.markdown,
          );

          expect(result.format, UrlContentFormat.markdown);
          expect(result.body, contains('# Hello'));
        },
      );

      test(
        'text format maps HTML to plain text',
        () {
          final response = _htmlResponse(
            '<h1>Title</h1><p>Paragraph with '
            '<a href="https://example.com">link</a> and '
            '<strong>bold</strong> text.</p>',
          );
          final result = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.text,
          );

          expect(result.format, UrlContentFormat.text);
          expect(result.body, contains('Title'));
          expect(result.body, contains('Paragraph'));
          expect(result.body, contains('link'));
          expect(result.body, contains('bold'));
          expect(result.body, isNot(contains('#')));
          expect(result.body, isNot(contains('**')));
          expect(result.body, isNot(contains('[')));
        },
      );

      test(
        'html format returns raw HTML body',
        () {
          const html = '<h1>Raw</h1><p>Content</p>';
          final response = _htmlResponse(html);
          final result = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.html,
          );

          expect(result.format, UrlContentFormat.html);
          expect(result.body, contains('<h1>Raw</h1>'));
          expect(result.body, contains('<p>Content</p>'));
        },
      );

      test(
        'html format returns raw HTML body (no stripping)',
        () {
          const html =
              '<html><script>alert(1)</script><body><p>Safe</p></body></html>';
          final response = _htmlResponse(html);
          final result = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.html,
          );

          expect(result.format, UrlContentFormat.html);
          expect(result.body, contains('<p>Safe</p>'));
          expect(result.body, contains('<script'));
        },
      );

      test(
        'text format strips script tags',
        () {
          final response = _htmlResponse(
            '<html><script>alert(1)</script><body><p>Safe</p></body></html>',
          );
          final result = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.text,
          );

          expect(result.format, UrlContentFormat.text);
          expect(result.body, contains('Safe'));
          expect(result.body, isNot(contains('alert')));
        },
      );

      test(
        'json content stays json regardless of requested format',
        () {
          final response = _jsonResponse('{"key": "value"}');

          final md = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.markdown,
          );
          expect(md.format, UrlContentFormat.json);
          expect(md.body, '{"key": "value"}');

          final txt = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.text,
          );
          expect(txt.format, UrlContentFormat.json);
          expect(txt.body, '{"key": "value"}');

          final html = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.html,
          );
          expect(html.format, UrlContentFormat.json);
          expect(html.body, '{"key": "value"}');
        },
      );

      test(
        'plain text stays text regardless of requested format',
        () {
          final response = _plainTextResponse('Hello world');

          final md = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.markdown,
          );
          expect(md.format, UrlContentFormat.text);
          expect(md.body, 'Hello world');

          final txt = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.text,
          );
          expect(txt.format, UrlContentFormat.text);
          expect(txt.body, 'Hello world');

          final html = transformer.transform(
            response,
            requestedFormat: UrlResponseFormat.html,
          );
          expect(html.format, UrlContentFormat.text);
          expect(html.body, 'Hello world');
        },
      );
    });

    group('Markdown escaping', () {
      test('escapes asterisks in text content', () {
        final response = _htmlResponse(
          '<p>Use the * wildcard</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'\*'));
        expect(result.body, isNot(contains('*wildcard*')));
      });

      test('escapes underscores in text content', () {
        final response = _htmlResponse(
          '<p>Variable _name is private</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'\_'));
      });

      test('escapes square brackets in text content', () {
        final response = _htmlResponse(
          '<p>Array [0] is first</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'\['));
        expect(result.body, contains(r'\]'));
      });

      test('escapes backticks in text content', () {
        final response = _htmlResponse(
          '<p>The ` char is special</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'\`'));
      });

      test('escapes pipe characters in text', () {
        final response = _htmlResponse(
          '<p>Use | as OR operator</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'\|'));
      });

      test('does not escape inside inline code', () {
        final response = _htmlResponse(
          '<p>Run <code>grep * | sort</code> to filter</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('`grep * | sort`'));
      });

      test('does not escape inside pre code blocks', () {
        final response = _htmlResponse(
          '<pre><code>const x = [1, 2];\nprint(*x);</code></pre>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('const x = [1, 2];'));
        expect(result.body, contains('print(*x);'));
      });

      test('backslash itself is escaped', () {
        final response = _htmlResponse(
          r'<p>Path is C:\Users\name</p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'C:\\Users\\name'));
      });
    });

    group('Recursive inline handling', () {
      test('preserves nested emphasis inside strong', () {
        final response = _htmlResponse(
          '<p>Read <strong><em>the docs</em></strong></p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('***the docs***'));
      });

      test('preserves nested link inside strong', () {
        final response = _htmlResponse(
          '<p>Visit <strong><a href="/docs">the docs</a></strong></p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('**[the docs](/docs)**'));
      });

      test('preserves nested code inside link text', () {
        final response = _htmlResponse(
          '<p>Check <a href="/api"><code>getUser()</code></a></p>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('[`getUser()`](/api)'));
      });

      test('preserves nested formatting inside heading', () {
        final response = _htmlResponse(
          '<h1>Welcome to <em>My</em> Site</h1>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('# Welcome to *My* Site'));
      });

      test('preserves nested formatting inside blockquote', () {
        final response = _htmlResponse(
          '<blockquote><p>This is <strong>very</strong> important</p></blockquote>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('> This is **very** important'));
      });
    });

    group('Table conversion', () {
      test('converts simple table to markdown', () {
        final response = _htmlResponse(
          '<table>'
          '<tr><th>Name</th><th>Type</th></tr>'
          '<tr><td>url</td><td>string</td></tr>'
          '<tr><td>count</td><td>number</td></tr>'
          '</table>',
        );
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, contains('| Name | Type |'));
        expect(result.body, contains('| --- | --- |'));
        expect(result.body, contains('| url | string |'));
        expect(result.body, contains('| count | number |'));
      });

      test('handles table with thead and tbody', () {
        final response = _htmlResponse(
          '<table>'
          '<thead><tr><th>Key</th><th>Value</th></tr></thead>'
          '<tbody><tr><td>a</td><td>1</td></tr></tbody>'
          '</table>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('| Key | Value |'));
        expect(result.body, contains('| a | 1 |'));
      });

      test('escapes pipe inside table cells', () {
        final response = _htmlResponse(
          '<table><tr><th>Expression</th></tr><tr><td>a | b</td></tr></table>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains(r'a \| b'));
      });

      test('handles empty table gracefully', () {
        final response = _htmlResponse('<table></table>');
        final result = transformer.transform(response);

        expect(result.format, UrlContentFormat.markdown);
        expect(result.body, isNot(contains('|')));
      });

      test('handles table with missing cells', () {
        final response = _htmlResponse(
          '<table>'
          '<tr><th>A</th><th>B</th><th>C</th></tr>'
          '<tr><td>1</td><td>2</td></tr>'
          '</table>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('| A | B | C |'));
        expect(result.body, contains('| 1 | 2 |  |'));
      });
    });

    group('Nested list indentation', () {
      test('indents nested unordered list items', () {
        final response = _htmlResponse(
          '<ul><li>Parent<ul><li>Child</li></ul></li></ul>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('- Parent'));
        expect(result.body, contains('  - Child'));
      });

      test('indents deeply nested list items', () {
        final response = _htmlResponse(
          '<ul><li>Level 1<ul><li>Level 2<ul><li>Level 3</li></ul></li></ul></li></ul>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('- Level 1'));
        expect(result.body, contains('  - Level 2'));
        expect(result.body, contains('    - Level 3'));
      });
    });

    group('Skip content tags', () {
      test('skips nav element content entirely', () {
        final response = _htmlResponse(
          '<nav><ul><li><a href="/">Home</a></li></ul></nav><main><p>Main content</p></main>',
        );
        final result = transformer.transform(response);

        expect(result.body, contains('Main content'));
        expect(result.body, isNot(contains('Home')));
      });
    });
  });
}

UrlResponse _htmlResponse(String html) {
  return _responseWithContentType(html, 'text/html');
}

UrlResponse _jsonResponse(String json) {
  return _responseWithContentType(json, 'application/json');
}

UrlResponse _plainTextResponse(String text) {
  return _responseWithContentType(text, 'text/plain');
}

UrlResponse _responseWithContentType(String body, String? contentType) {
  return UrlResponse(
    statusCode: 200,
    body: body,
    headers: contentType != null
        ? {
            'content-type': [contentType],
          }
        : {},
    elapsed: Duration.zero,
  );
}
