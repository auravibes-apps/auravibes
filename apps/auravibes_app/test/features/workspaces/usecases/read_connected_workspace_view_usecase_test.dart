import 'package:auravibes_app/features/workspaces/models/workspace_connected_binding.dart';
import 'package:auravibes_app/features/workspaces/usecases/read_connected_workspace_view_usecase.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('read delegates exact saved contract to common executor', () async {
    final calls = <Map<String, dynamic>>[];
    final binding = WorkspaceConnectedBinding(
      toolId: 'connector/example/read',
      revision: connectorToolRevision(_connector, _tool),
      connectionId: 'service:chosen',
      inputs: {'query': 'name'},
    );
    final read = ReadConnectedWorkspaceViewUsecase(
      connectors: const [_connector],
      execute: (arguments) async {
        calls.add(arguments);

        return {'result': 'live'};
      },
    );
    expect(await read(binding), {'result': 'live'});
    expect(calls.single, {
      'toolId': binding.toolId,
      'revision': binding.revision,
      'connectionId': binding.connectionId,
      'args': binding.inputs,
    });
  });
  test('rejects stale contracts before executing', () async {
    var called = false;
    final read = ReadConnectedWorkspaceViewUsecase(
      connectors: const [_connector],
      execute: (_) async {
        called = true;

        return null;
      },
    );
    expect(
      () => read(
        const WorkspaceConnectedBinding(
          toolId: 'connector/example/read',
          revision: 'old',
          inputs: {'query': 'name'},
          connectionId: 'service:chosen',
        ),
      ),
      throwsA(isA<Exception>()),
    );
    expect(called, false);
  });
  test('rejects schema-invalid arguments before executing', () async {
    final read = ReadConnectedWorkspaceViewUsecase(
      connectors: const [_connector],
      execute: (_) async => fail('must not execute'),
    );
    expect(
      () => read(
        WorkspaceConnectedBinding(
          toolId: 'connector/example/read',
          revision: connectorToolRevision(_connector, _tool),
          inputs: const {'query': 7},
          connectionId: 'service:chosen',
        ),
      ),
      throwsFormatException,
    );
  });
  test('requires explicit Connection instead of guessing', () {
    final read = ReadConnectedWorkspaceViewUsecase(
      connectors: const [_connector],
      execute: (_) async => fail('must not execute'),
    );
    expect(
      () => read(
        WorkspaceConnectedBinding(
          toolId: 'connector/example/read',
          revision: connectorToolRevision(_connector, _tool),
          inputs: const {'query': 'name'},
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
  test('automatic View reads never execute write tools', () {
    const write = ConnectorToolDefinition(
      slug: 'write',
      title: 'Write',
      description: 'Write',
      urlTemplate: .new(
        template: .new(
          url: 'https://example.invalid/write',
          method: UrlRequestMethod.post,
        ),
        inputs: {},
      ),
    );
    const connector = ConnectorDefinition(
      identifier: 'writer',
      title: 'Writer',
      description: 'Writer',
      tools: [write],
    );
    final read = ReadConnectedWorkspaceViewUsecase(
      connectors: const [connector],
      execute: (_) async => fail('write must never run'),
    );
    expect(
      () => read(
        WorkspaceConnectedBinding(
          toolId: connectorToolId(connector, write),
          revision: connectorToolRevision(connector, write),
          inputs: const {},
        ),
      ),
      throwsA(isA<Exception>()),
    );
  });
}

const _tool = ConnectorToolDefinition(
  slug: 'read',
  title: 'Read',
  description: 'Read',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
    },
    'required': ['query'],
    'additionalProperties': false,
  },
  urlTemplate: .new(
    template: .new(url: 'https://example.invalid/read'),
    inputs: {},
  ),
  requiresConnection: true,
);
const _connector = ConnectorDefinition(
  identifier: 'example',
  title: 'Example',
  description: 'Example',
  tools: [_tool],
);
