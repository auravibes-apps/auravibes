// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
import 'package:auravibes_app/domain/entities/mcp_transport_type.dart';
import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('McpToolInfo', () {
    test('creates with required fields', () {
      const info = McpToolInfo(
        toolName: 'read_file',
        description: 'Reads a file',
        inputSchema: {'type': 'object'},
      );
      expect(info.toolName, 'read_file');
      expect(info.description, 'Reads a file');
      expect(info.inputSchema, {'type': 'object'});
    });

    test('optional fields', () {
      const info = McpToolInfo(
        toolName: 't',
        description: 'd',
        inputSchema: {},
        supportsProgress: true,
        supportsCancellation: true,
        metadata: {'key': 'value'},
      );
      expect(info.supportsProgress, isTrue);
      expect(info.supportsCancellation, isTrue);
      expect(info.metadata, {'key': 'value'});
    });

    test('finalToolName generates composite name', () {
      const info = McpToolInfo(
        toolName: 'read file!',
        description: 'd',
        inputSchema: {},
      );
      final server = McpServerEntity(
        id: '42',
        workspaceId: 'ws',
        name: 'My Server',
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final name = info.finalToolName(server);
      expect(name, 'mcp_42_my-server_read_file_');
    });

    test('finalToolName sanitizes special chars', () {
      const info = McpToolInfo(
        toolName: 'tool with spaces',
        description: 'd',
        inputSchema: {},
      );
      final server = McpServerEntity(
        id: '1',
        workspaceId: 'ws',
        name: 'Server',
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final name = info.finalToolName(server);
      expect(name, 'mcp_1_server_tool_with_spaces');
    });
  });

  group('MCPServerWithTools', () {
    test('slugServerName delegates to server', () {
      final server = McpServerEntity(
        id: '1',
        workspaceId: 'ws',
        name: 'My Server!',
        url: 'http://localhost',
        transport: const McpTransportTypeSSE(),
        authenticationType: const McpAuthenticationTypeNone(),
        createdAt: DateTime(2025),
        updatedAt: DateTime(2025),
      );
      final withTools = MCPServerWithTools(server: server, tools: []);
      expect(withTools.slugServerName, server.slugServerName);
    });
  });
}
