import 'dart:convert';
import 'dart:typed_data';

import 'package:auravibes_app/data/database/drift/app_database.dart';
import 'package:auravibes_app/data/repositories/local_workspace_table_repository.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_asset.dart';
import 'package:auravibes_app/features/workspaces/usecases/workspace_conversation_command_usecase.dart';
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

    return content;
  }

  @override
  Future<WorkspaceAsset> upload(String name, Uint8List bytes) =>
      throw UnimplementedError();
}

class _Files implements WorkspaceFileRepository {
  @override
  Future<WorkspaceFile> file(String id) async =>
      WorkspaceFile(id: id, name: 'notes.txt', assetId: 'asset', revision: 1);
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
