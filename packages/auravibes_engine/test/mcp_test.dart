import 'dart:convert';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test('preserves simple text and normalizes rich results', () {
    expect(
      McpToolResult(content: [McpTextContent('hello')]).toModelText(),
      'hello',
    );
    final result = McpToolResult(
      content: [
        McpTextContent('first'),
        McpBinaryContent(type: 'image', mimeType: 'image/png', data: 'AA=='),
        McpResourceContent(uri: 'file:///note', text: 'note'),
      ],
      structuredContent: {'count': 3},
      isError: true,
    );
    expect(jsonDecode(result.toModelText()), {
      'content': [
        {'type': 'text', 'text': 'first'},
        {'type': 'image', 'mimeType': 'image/png', 'data': 'AA=='},
        {'type': 'resource', 'uri': 'file:///note', 'text': 'note'},
      ],
      'structuredContent': {'count': 3},
      'isStreaming': false,
      'isError': true,
    });
    expect(result.toModelText(), result.toModelText());
  });

  test('normalizes empty and multiple content', () {
    expect(jsonDecode(McpToolResult().toModelText()), {
      'content': <Object?>[],
      'isStreaming': false,
    });
    expect(
      jsonDecode(
        McpToolResult(
          content: [McpTextContent('one'), McpTextContent('two')],
        ).toModelText(),
      ),
      {
        'content': [
          {'type': 'text', 'text': 'one'},
          {'type': 'text', 'text': 'two'},
        ],
        'isStreaming': false,
      },
    );
  });
}
