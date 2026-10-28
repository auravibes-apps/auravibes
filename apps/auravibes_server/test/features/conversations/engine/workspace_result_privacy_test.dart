import 'dart:convert';

import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server/src/features/conversations/engine/workspace_result_privacy.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('cloud directory results keep safe item metadata', () {
    final now = DateTime.utc(2026);
    final call = ConversationToolCall(
      workspaceId: 1,
      conversationId: 1,
      turnId: 1,
      messageId: 1,
      stableId: 'directory-read',
      name: workspaceReadDirectoryToolName,
      argumentsJson: jsonEncode({'path': '/'}),
      argumentsDigest: 'digest',
      status: 'success',
      revision: 1,
      createdAt: now,
      updatedAt: now,
    );

    final safe = jsonDecode(
      safeWorkspaceResult(
        call,
        jsonEncode({
          'kind': 'directory',
          'path': '/',
          'entries': [
            {
              'id': 'table-1',
              'kind': 'table',
              'name': 'Contacts',
              'path': 'Contacts',
              'revision': 2,
              'columns': ['private schema'],
            },
          ],
          'private': 'private result',
        }),
      ),
    );

    expect(safe, {
      'kind': 'directory',
      'path': '/',
      'entries': [
        {
          'id': 'table-1',
          'kind': 'table',
          'name': 'Contacts',
          'path': 'Contacts',
          'revision': 2,
        },
      ],
      'truncated': false,
    });
  });
}
