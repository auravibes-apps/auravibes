import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/conversation_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_context_repository.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/domain/entities/sanitize_workspace_tool_result.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/usecases/project_workspace_chat_context_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_tools_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:crypto/crypto.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('escaped file output stays valid JSON and marks truncation', () {
    final output = workspaceFileToolResult(
      id: 'file',
      name: 'notes.txt',
      mimeType: 'text/plain',
      revision: 1,
      content: List.filled(20000, '\n').join(),
    );
    final encoded = jsonEncode(output);
    expect(utf8.encode(encoded).length, lessThanOrEqualTo(12 * 1024));
    expect(jsonDecode(encoded), isA<Map<String, dynamic>>());
    expect(output['truncated'], isTrue);
  });

  test(
    'file grant is isolated to its chat and revocation blocks reads',
    () async {
      final database = AppDatabase(connection: NativeDatabase.memory());
      addTearDown(database.close);
      final _ = await database
          .into(database.workspaces)
          .insert(
            WorkspacesCompanion.insert(
              id: const .new('one'),
              name: 'One',
              type: .local,
            ),
          );
      final conversations = ConversationRepository(database);
      final first = await conversations.createConversation(
        const .new(title: 'One', workspaceId: 'one'),
      );
      final second = await conversations.createConversation(
        const .new(title: 'Two', workspaceId: 'one'),
      );
      final context = LocalWorkspaceContextRepository(database, 'one');
      final selection = WorkspaceContextSelection(
        workspaceId: 'one',
        conversationId: first.id,
        itemId: 'file',
        kind: 'file',
      );
      final _ = await context.save(first.id, 'grant', selection);
      final command = WorkspaceConversationCommandUsecase(
        tables: .new(LocalWorkspaceTableRepository(database, 'one')),
        files: .new(_Files()),
        assets: .new(_Assets(.fromList(utf8.encode('Hello')))),
      );
      final tools = WorkspaceConversationToolsUsecase(
        conversations: conversations,
        context: (_) => context,
        commands: (_) async => command,
      );
      final args = {'action': 'read', 'id': 'file'};
      final result = await tools.call(
        conversationId: first.id,
        arguments: args,
      );
      expect(
        result,
        isA<Map<String, Object?>>().having(
          (item) => item['content'],
          'content',
          'Hello',
        ),
      );
      final storedCall = sanitizeWorkspaceToolResult(
        .new(
          id: 'file-read',
          name: workspaceCommandToolName,
          argumentsRaw: jsonEncode(args),
          responseRaw: jsonEncode(result),
          responseContextRaw: jsonEncode(result),
          resultStatus: .success,
        ),
      );
      expect(jsonEncode(storedCall.toJson()), isNot(contains('Hello')));
      final message = MessageEntity(
        id: 'tool-message',
        conversationId: first.id,
        content: '',
        messageType: .toolCall,
        isUser: false,
        status: .sent,
        createdAt: .new(2026),
        updatedAt: .new(2026),
        metadata: .new(toolCalls: [storedCall]),
      );
      final projection = ProjectWorkspaceChatContextUsecase(tools);
      final authorized = await projection([message]);
      expect(
        authorized.single.metadata?.toolCalls.single.responseRaw,
        contains('Hello'),
      );
      await expectLater(
        tools.call(conversationId: second.id, arguments: args),
        throwsA(isA<Object>()),
      );
      final _ = await context.save(first.id, 'revoke', null);
      final revokedProjection = await projection([message]);
      expect(
        revokedProjection.single.metadata?.toolCalls.single.responseRaw,
        workspaceContextUnavailable,
      );
      await expectLater(
        tools.call(conversationId: first.id, arguments: args),
        throwsA(isA<Object>()),
      );
    },
  );

  test('file replacement or deletion during preview blocks output', () async {
    for (final delete in [false, true]) {
      final database = AppDatabase(connection: NativeDatabase.memory());
      final assets = _Assets(.fromList(utf8.encode('Hello')));
      final gate = Completer<void>();
      final started = Completer<void>();
      assets
        ..gate = gate
        ..started = started;
      final files = _Files();
      final command = WorkspaceConversationCommandUsecase(
        tables: .new(LocalWorkspaceTableRepository(database, 'one')),
        files: .new(files),
        assets: .new(assets),
      );
      final selection = WorkspaceContextSelection(
        workspaceId: 'one',
        conversationId: 'chat',
        itemId: 'file',
        kind: 'file',
      );
      final pending = command.call(
        selection: selection,
        arguments: {'action': 'read', 'id': 'file'},
      );
      await started.future;
      files
        ..deleted = delete
        ..revision = 2;
      gate.complete();
      await expectLater(pending, throwsA(isA<Object>()));
      await database.close();
    }
  });

  test('only the selected small verified text file can be read', () async {
    final database = AppDatabase(connection: NativeDatabase.memory());
    addTearDown(database.close);
    final bytes = Uint8List.fromList(utf8.encode('Hello'));
    final assets = _Assets(bytes);
    final command = WorkspaceConversationCommandUsecase(
      tables: .new(LocalWorkspaceTableRepository(database, 'one')),
      files: .new(_Files()),
      assets: .new(assets),
    );
    final selection = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: 'chat',
      itemId: 'file',
      kind: 'file',
    );
    expect(
      WorkspaceContextSelection.decode(selection.toJson(), 'one', 'chat')?.kind,
      'file',
    );
    final result = await command.call(
      selection: selection,
      arguments: {'action': 'read', 'id': 'file'},
    );
    expect(result['content'], 'Hello');
    await expectLater(
      command.call(
        selection: selection,
        arguments: {'action': 'read', 'id': 'other'},
      ),
      throwsA(isA<Object>()),
    );
    final folder = WorkspaceContextSelection(
      workspaceId: 'one',
      conversationId: 'chat',
      itemId: '',
      kind: 'directory',
    );
    await expectLater(
      command.call(
        selection: folder,
        arguments: {'action': 'read', 'id': 'file'},
      ),
      throwsA(isA<Object>()),
    );
    assets
      ..declaredSize = 65537
      ..reads = 0;
    await expectLater(
      command.call(
        selection: selection,
        arguments: {'action': 'read', 'id': 'file'},
      ),
      throwsA(isA<Object>()),
    );
    expect(assets.reads, 0);
    assets
      ..declaredSize = null
      ..invalidChecksum = true;
    await expectLater(
      command.call(
        selection: selection,
        arguments: {'action': 'read', 'id': 'file'},
      ),
      throwsA(isA<WorkspaceAssetException>()),
    );
  });
}

class _Assets implements WorkspaceAssetRepository {
  new(this.content);
  final Uint8List content;
  int? declaredSize;
  bool invalidChecksum = false;
  int reads = 0;
  Completer<void>? gate;
  Completer<void>? started;
  @override
  Future<WorkspaceAsset> asset(String id) async => WorkspaceAsset(
    id: id,
    name: 'notes.txt',
    mimeType: 'text/plain',
    sizeBytes: declaredSize ?? content.length,
    checksum: invalidChecksum ? 'invalid' : sha256.convert(content).toString(),
  );
  @override
  Future<Uint8List> bytes(String id) async {
    reads++;
    started?.complete();
    await gate?.future;

    return content;
  }

  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) =>
      throw UnimplementedError();
}

class _Files implements WorkspaceFileRepository {
  bool deleted = false;
  int revision = 1;
  @override
  Future<WorkspaceFile> file(String id) async {
    if (deleted) throw const WorkspaceAssetException(.denied);

    return WorkspaceFile(
      id: id,
      name: 'notes.txt',
      assetId: 'asset',
      revision: revision,
    );
  }

  @override
  Future<List<WorkspaceFile>> list({String? parentId}) =>
      throw UnimplementedError();
  @override
  Future<WorkspaceFile> create(
    WorkspaceFileDraft draft, {
    bool sharingApproved = false,
  }) => throw UnimplementedError();
  @override
  Future<WorkspaceFile> updateMetadata({
    required WorkspaceFile file,
    required String name,
    required String? parentId,
  }) => throw UnimplementedError();
}
