import 'dart:io';

import 'package:auravibes_server/src/features/model_connections/usecases/model_connection_usecases.dart';
import 'package:auravibes_server/src/generated/protocol.dart';
import 'package:test/test.dart';

void main() {
  test('provider catalog contract is typed, bounded, and SSRF-safe', () async {
    expect(defaultProviderUrl('openai'), 'https://api.openai.com/v1');
    expect(
      providerHeaders('anthropic', 'secret'),
      containsPair('x-api-key', 'secret'),
    );
    expect(
      parseModelIds({
        'data': List.generate(3, (index) => {'id': 'model-$index'}),
      }, maxModels: 2),
      ['model-0', 'model-1'],
    );
    await expectLater(
      requirePublicHttpsUri(
        'https://metadata.example/models',
        lookup: (_) async => [InternetAddress('127.0.0.1')],
      ),
      throwsA(anything),
    );
    await expectLater(
      requirePublicHttpsUri(
        'https://api.example/models',
        lookup: (_) async => [InternetAddress('8.8.8.8')],
      ),
      completion(Uri.parse('https://api.example/models')),
    );
    final validated = await validatePublicHttpsUri(
      'https://api.example/models',
      lookup: (_) async => [InternetAddress('8.8.4.4')],
    );
    expect(validated.address.address, '8.8.4.4');
    pinnedHttpClient(validated.address).close(force: true);
  });

  test('dedicated model endpoint contracts contain metadata but no secret', () {
    final create = CreateModelConnectionRequest(
      workspaceId: 1,
      requestId: 'request',
      connectionId: 'connection',
      name: 'OpenAI',
      providerId: 'openai',
    );
    final update = UpdateModelConnectionRequest(
      workspaceId: 1,
      requestId: 'request',
      connectionId: 'connection',
      expectedRevision: 1,
      name: 'OpenAI',
    );

    expect(create.toJson(), isNot(contains('secret')));
    expect(update.toJson()['expectedRevision'], 1);
    expect(ListModelConnectionsRequest(workspaceId: 1).workspaceId, 1);
    expect(ListWorkspaceModelSelectionsRequest(workspaceId: 1).workspaceId, 1);
  });
}
