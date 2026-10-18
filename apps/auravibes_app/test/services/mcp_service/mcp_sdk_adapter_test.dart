import 'dart:convert';

import 'package:auravibes_app/services/mcp_service/mcp_sdk_adapter.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mcp_client/mcp_client.dart' as mcp;

void main() {
  test('maps every SDK result variant', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [
          mcp.TextContent(annotations: .new(priority: 0.7), text: 'text'),
          mcp.ImageContent(
            annotations: .new(priority: 0.7),
            data: 'AA==',
            mimeType: 'image/png',
          ),
          mcp.AudioContent(data: 'AQ==', mimeType: 'audio/wav'),
          mcp.EmbeddedResource(
            resource: mcp.TextResourceContents(
              text: 'resource',
              uri: 'file:///a',
            ),
          ),
          mcp.ResourceLink(
            meta: {'x': true},
            name: 'Example',
            uri: 'https://example.test',
          ),
        ],
        isError: true,
        structuredContent: {'ok': true},
      ),
    );

    final [text, image, _, resource, resourceLink] = result.content;
    final typedText = text as McpTextContent;
    final typedImage = image as McpBinaryContent;
    final typedResource = resource as McpResourceContent;
    final typedResourceLink = resourceLink as McpResourceContent;

    expect(result.content, [
      isA<McpTextContent>(),
      isA<McpBinaryContent>(),
      isA<McpBinaryContent>(),
      isA<McpResourceContent>(),
      isA<McpResourceContent>(),
    ]);
    expect(typedText.annotations, {'priority': 0.7});
    expect(typedImage.data, 'AA==');
    expect(typedImage.mimeType, 'image/png');
    expect(typedImage.url, isNull);
    expect(typedResource.uri, 'file:///a');
    expect(typedResource.text, 'resource');
    expect(typedResource.isLink, isFalse);
    expect(typedResourceLink.uri, 'https://example.test');
    expect(typedResourceLink.name, 'Example');
    expect(typedResourceLink.isLink, isTrue);
    expect(typedResourceLink.meta, {'x': true});
    expect(result.structuredContent, {'ok': true});
    expect(result.isError, isTrue);
  });

  test('preserves array structured content', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [mcp.TextContent(text: 'ok')],
        structuredContent: ['ok', 2],
      ),
    );

    expect(result.structuredContent, ['ok', 2]);
  });

  for (final isError in [null, false, true]) {
    test('preserves mixed content and metadata with isError=$isError', () {
      final result = McpSdkAdapter.toolResult(
        .fromJson({
          'content': [
            {
              'type': 'text',
              'text': 'before',
              'annotations': {'priority': 0.7},
            },
            {
              'type': 'future',
              'payload': 'secret-payload',
              'annotations': {'secret': 'secret-annotation'},
              '_meta': {'token': 'secret-token'},
            },
            {'type': 'image', 'data': 'AA==', 'mimeType': 'image/png'},
            {'type': 'text', 'text': 'after'},
          ],
          'structuredContent': {'ok': true},
          'isError': ?isError,
        }),
      );

      expect(jsonDecode(result.toModelText()), {
        'content': [
          {
            'type': 'text',
            'text': 'before',
            'annotations': {'priority': 0.7},
          },
          {'type': 'text', 'text': '[Unsupported MCP content: future]'},
          {'type': 'image', 'mimeType': 'image/png', 'data': 'AA=='},
          {'type': 'text', 'text': 'after'},
        ],
        'structuredContent': {'ok': true},
        'isStreaming': false,
        'isError': ?isError,
      });
      expect(result.isError, isError);
    });
  }

  test('returns safe fallback for unknown-only content', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [
          mcp.UnknownContentBlock.fromJson({
            'type': 'future_block-v2',
            'payload': 'secret-payload',
          }),
        ],
      ),
    );

    expect(result.toModelText(), '[Unsupported MCP content: future_block-v2]');
    expect(result.structuredContent, isNull);
    expect(result.isError, isNull);
  });

  test('omits missing, malformed, unsafe and oversized content kinds', () {
    for (final type in <Object?>[
      null,
      42,
      ['future'],
      {'kind': 'future'},
      '',
      'future\nsecret',
      'future\n',
      'Bearer secret-token',
      'https://example.test?token=secret-token',
      String.fromCharCode(0xe9),
      'a' * 33,
    ]) {
      final result = McpSdkAdapter.toolResult(
        .new(
          content: [
            mcp.UnknownContentBlock.fromJson({
              'type': ?type,
              'payload': 'secret-payload',
            }),
          ],
        ),
      );

      expect(result.toModelText(), '[Unsupported MCP content: unknown]');
    }
  });

  test('maps blob-backed embedded resources', () {
    final result = McpSdkAdapter.toolResult(
      .new(
        content: [
          mcp.EmbeddedResource(
            resource: mcp.BlobResourceContents(
              blob: 'AQID',
              mimeType: 'application/octet-stream',
              uri: 'file:///blob',
            ),
          ),
        ],
      ),
    );

    final resource = result.content.single as McpResourceContent;
    expect(resource.uri, 'file:///blob');
    expect(resource.blob, 'AQID');
    expect(resource.mimeType, 'application/octet-stream');
    expect(resource.text, isNull);
    expect(resource.isLink, isFalse);
  });
}
