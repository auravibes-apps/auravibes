import 'dart:convert';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/agent_adapters/scoped_verification_identity_resolver.dart';
import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'origin identity excludes a later user message and rejects ambiguous calls',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const Value('workspace'),
              name: 'Local',
              type: .local,
            ),
          );
      final _ = await database
          .into(database.conversations)
          .insert(
            ConversationsCompanion.insert(
              id: const Value('chat'),
              workspaceId: 'workspace',
              title: 'Work',
            ),
          );
      final metadata = jsonEncode(
        const MessageMetadataEntity(
          toolCalls: [
            MessageToolCallEntity(id: 'call', name: 'edit', argumentsRaw: '{}'),
          ],
        ).toJson(),
      );
      Future<void> message(String id, {required bool user, String? data}) async {
        final _ = await database
            .into(database.messages)
            .insert(
              MessagesCompanion.insert(
                id: .new(id),
                conversationId: 'chat',
                content: 'Message',
                messageType: .text,
                isUser: user,
                status: .sent,
                metadata: .new(data),
              ),
            );
      }

      await message('origin', user: true);
      await message('assistant', user: false, data: metadata);
      await message('later-user', user: true);
      final resolver = ScopedVerificationIdentityResolver(database);
      final invocation = (
        conversationId: 'chat',
        toolCallId: 'call',
        tool: ResolvedTool.mcp(
          tableId: 'edit',
          toolIdentifier: 'edit',
          mcp: (
            mcpServerId: 'server',
            mcpSlug: 'server',
            outputSchemaJson: null,
          ),
        ),
      );
      expect(await resolver(invocation), (
        workspaceId: 'workspace',
        turnId: 'origin',
      ));
      await message('ambiguous-assistant', user: false, data: metadata);
      expect((await resolver(invocation))?.turnId, isNull);
    },
  );
}
