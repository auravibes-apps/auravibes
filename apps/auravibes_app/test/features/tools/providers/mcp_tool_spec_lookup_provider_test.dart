import 'package:auravibes_app/domain/entities/tool_spec.dart';
import 'package:auravibes_app/features/tools/providers/mcp_tool_spec_lookup_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';

ToolSpec? _fakeGetToolSpec({
  required String mcpServerId,
  required String toolName,
}) {
  if (mcpServerId == 'srv-1' && toolName == 'my-tool') {
    return const ToolSpec(
      name: 'my-tool',
      description: 'desc',
      inputJsonSchema: {},
    );
  }
  return null;
}

void main() {
  group('mcpToolSpecLookupProvider', () {
    test('returns McpToolSpecLookup instance', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            McpToolSpecLookup(
              call: ({required mcpServerId, required toolName}) => null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      expect(lookup, isA<McpToolSpecLookup>());
    });

    test('call returns null when no matching tool found', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            McpToolSpecLookup(
              call: ({required mcpServerId, required toolName}) => null,
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      final result = lookup.call(mcpServerId: 'srv-1', toolName: 'unknown');
      expect(result, isNull);
    });

    test('call returns ToolSpec when matching tool exists', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            const McpToolSpecLookup(call: _fakeGetToolSpec),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      final result = lookup.call(mcpServerId: 'srv-1', toolName: 'my-tool');
      expect(result, isNotNull);
      expect(result!.name, 'my-tool');
    });

    test('call returns null for non-matching server', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            const McpToolSpecLookup(call: _fakeGetToolSpec),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      final result = lookup.call(mcpServerId: 'other-srv', toolName: 'my-tool');
      expect(result, isNull);
    });

    test('McpToolSpecLookup stores call callback', () {
      ToolSpec? captured({
        required String mcpServerId,
        required String toolName,
      }) {
        return const ToolSpec(
          name: 'x',
          description: 'd',
          inputJsonSchema: {},
        );
      }

      final lookup = McpToolSpecLookup(call: captured);
      expect(lookup.call, isA<Function>());
      final result = lookup.call(mcpServerId: 's', toolName: 't');
      expect(result, isNotNull);
      expect(result!.name, 'x');
    });

    test('McpToolSpecLookup is const constructible', () {
      const lookup = McpToolSpecLookup(
        call: _fakeGetToolSpec,
      );
      expect(lookup.call, isA<Function>());
    });

    test('call receives correct parameters', () {
      String? capturedServerId;
      String? capturedToolName;

      ToolSpec? trackingCallback({
        required String mcpServerId,
        required String toolName,
      }) {
        capturedServerId = mcpServerId;
        capturedToolName = toolName;
        return null;
      }

      final lookup = McpToolSpecLookup(call: trackingCallback);
      lookup.call(mcpServerId: 'server-abc', toolName: 'tool-xyz');
      expect(capturedServerId, 'server-abc');
      expect(capturedToolName, 'tool-xyz');
    });

    test('call returning null for missing server still returns null', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            const McpToolSpecLookup(call: _fakeGetToolSpec),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      final result = lookup.call(
        mcpServerId: 'missing-srv',
        toolName: 'missing-tool',
      );
      expect(result, isNull);
    });

    test('multiple calls with different params return different results', () {
      final container = ProviderContainer(
        overrides: [
          mcpToolSpecLookupProvider.overrideWithValue(
            const McpToolSpecLookup(call: _fakeGetToolSpec),
          ),
        ],
      );
      addTearDown(container.dispose);

      final lookup = container.read(mcpToolSpecLookupProvider);
      final result1 = lookup.call(mcpServerId: 'srv-1', toolName: 'my-tool');
      final result2 = lookup.call(mcpServerId: 'other', toolName: 'other');
      expect(result1, isNotNull);
      expect(result2, isNull);
    });
  });
}
