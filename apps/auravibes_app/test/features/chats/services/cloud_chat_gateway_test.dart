import 'dart:convert';

import 'package:auravibes_app/features/chats/services/cloud_chat_gateway.dart';
import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_server_client/auravibes_server_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const _workspace = CloudWorkspaceRef(
  localWorkspaceId: 'local',
  serverUrl: 'https://example.com/',
  accountId: 'account',
  cloudWorkspaceId: 1,
);

void main() {
  test('cloud HTTP requests advertise supported catalog components', () async {
    final requests = <String, Map<String, dynamic>>{};
    final client = Client(
      _workspace.serverUrl,
      httpClientOverride: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        requests[request.url.pathSegments.last] =
            body['request'] as Map<String, dynamic>;

        return http.Response(
          'Test transport stopped after request capture',
          500,
        );
      }),
    );
    addTearDown(client.close);
    final gateway = CloudChatGateway(
      .new(client: client, workspace: _workspace),
    );
    final operations = <String, Future<Object?> Function()>{
      'startTurn': () => gateway.startTurn(
        requestId: 'start',
        conversationId: 'conversation',
        expectedConversationRevision: 1,
        clientMessageId: 'message',
        content: 'Hello',
        attachmentIds: const [],
      ),
      'continueTurn': () => gateway.continueTurn(
        requestId: 'continue',
        conversationId: 'conversation',
        expectedConversationRevision: 1,
      ),
      'continueConversation': () => gateway.continueConversation(
        requestId: 'execute',
        conversationId: 'conversation',
        expectedProjectionRevision: 1,
      ),
      'submitToolDecision': () => gateway.submitToolDecision(
        requestId: 'decision',
        turnId: 'turn',
        toolCallId: 'tool',
        argumentsDigest: 'digest',
        expectedTurnRevision: 1,
        decision: 'approve',
      ),
      'queueConversationMessage': () => gateway.queueConversationMessage(
        requestId: 'queue',
        conversationId: 'conversation',
        expectedProjectionRevision: 1,
        clientMessageId: 'message',
        content: 'Hello',
        attachmentIds: const [],
        metadataJson: '{"action":"unchanged"}',
      ),
      'stopConversation': () => gateway.stopConversation(
        requestId: 'stop',
        conversationId: 'conversation',
        expectedProjectionRevision: 1,
      ),
      'getTurn': () => gateway.getTurn(turnId: 'turn'),
      'getConversationSnapshot': () =>
          gateway.getConversationSnapshot('conversation'),
      'listMessages': () => gateway.listConversationMessages('conversation'),
    };
    for (final entry in operations.entries) {
      await expectLater(entry.value(), throwsA(anything));
      expect(requests, contains(entry.key));
      expect(
        requests[entry.key]!['a2uiSupportedComponents'],
        unorderedEquals(supportedA2uiChatComponents),
        reason: entry.key,
      );
    }
    expect(
      requests['queueConversationMessage']!['metadataJson'],
      '{"action":"unchanged"}',
    );
  });

  test('cloud subscriptions advertise supported components', () async {
    final gateway = CloudChatGateway.forConversationTesting(
      stateGateway: .forTesting(
        workspace: _workspace,
        readState: (_) => throw UnimplementedError(),
        subscribe: (_) => const Stream.empty(),
      ),
      subscribeConversation: (request) {
        expect(
          request.a2uiSupportedComponents,
          unorderedEquals(supportedA2uiChatComponents),
        );
        expect(request.afterSequence, 7);

        return const Stream.empty();
      },
      getConversationSnapshot: (_) => throw UnimplementedError(),
    );

    await gateway
        .subscribeConversation('conversation', afterSequence: 7)
        .drain<void>();
  });
}
