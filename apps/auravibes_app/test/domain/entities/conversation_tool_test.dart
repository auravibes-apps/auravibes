// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
import 'package:auravibes_app/domain/entities/conversation_tool_entity.dart';
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2025);

  group('ConversationToolEntity', () {
    final entity = ConversationToolEntity(
      conversationId: 'conv_1',
      toolId: 'tool_1',
      isEnabled: true,
      permissionMode: ToolPermissionMode.alwaysAsk,
      createdAt: now,
      updatedAt: now,
    );

    test('isAvailable mirrors isEnabled', () {
      expect(entity.isAvailable, isTrue);

      final disabled = ConversationToolEntity(
        conversationId: 'conv_2',
        toolId: 'tool_2',
        isEnabled: false,
        permissionMode: ToolPermissionMode.alwaysAsk,
        createdAt: now,
        updatedAt: now,
      );
      expect(disabled.isAvailable, isFalse);
    });

    test('permissionMode - alwaysAsk', () {
      expect(entity.permissionMode, ToolPermissionMode.alwaysAsk);
    });

    test('permissionMode - alwaysAllow', () {
      final allowed = ConversationToolEntity(
        conversationId: 'conv_3',
        toolId: 'tool_3',
        isEnabled: true,
        permissionMode: ToolPermissionMode.alwaysAllow,
        createdAt: now,
        updatedAt: now,
      );
      expect(allowed.permissionMode, ToolPermissionMode.alwaysAllow);
    });
  });

  group('ConversationToolToCreate', () {
    test('hasValidToolId true when toolId is not empty', () {
      const create = ConversationToolToCreate(toolId: 'tool_1');
      expect(create.hasValidToolId, isTrue);
    });

    test('hasValidToolId false when toolId is empty', () {
      const create = ConversationToolToCreate(toolId: '');
      expect(create.hasValidToolId, isFalse);
    });

    test('defaultEnabled returns true when not specified', () {
      const create = ConversationToolToCreate(toolId: 'tool_1');
      expect(create.defaultEnabled, isTrue);
    });

    test('defaultEnabled returns isEnabled when specified', () {
      const create = ConversationToolToCreate(
        toolId: 'tool_1',
        isEnabled: false,
      );
      expect(create.defaultEnabled, isFalse);
    });

    test('defaultPermissionMode returns alwaysAsk when not specified', () {
      const create = ConversationToolToCreate(toolId: 'tool_1');
      expect(create.defaultPermissionMode, ToolPermissionMode.alwaysAsk);
    });

    test('defaultPermissionMode returns specified mode', () {
      const create = ConversationToolToCreate(
        toolId: 'tool_1',
        permissionMode: ToolPermissionMode.alwaysAllow,
      );
      expect(create.defaultPermissionMode, ToolPermissionMode.alwaysAllow);
    });
  });
}
