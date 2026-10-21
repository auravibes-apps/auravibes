import 'package:auravibes_app/features/service_connections/usecases/connector_command_usecase.dart';
import 'package:auravibes_app/features/skills/models/app_skill_credential_candidate.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectorCommandUsecase', () {
    test('executes a known tool ID without a discovery call', () async {
      final loadedWorkspaceIds = <String>[];
      final calls =
          <
            ({
              String workspaceId,
              AppSkillDefinition connector,
              AppSkillToolDefinition tool,
              Map<String, dynamic> arguments,
            })
          >[];
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
        ],
        onLoadConnections: (workspaceId, _) async {
          loadedWorkspaceIds.add(workspaceId);

          return const [
            AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
          ];
        },
        onRun:
            ({
              required workspaceId,
              required connector,
              required tool,
              required arguments,
            }) async {
              calls.add((
                workspaceId: workspaceId,
                connector: connector,
                tool: tool,
                arguments: arguments,
              ));

              return 'done';
            },
      );
      final result = await usecase.call(
        workspaceId: 'workspace-current',
        commandName: executeConnectorToolName,
        arguments: {
          'toolId': 'connector/example/search',
          'args': {'query': 'find a record'},
        },
      );

      expect(result, 'done');
      expect(loadedWorkspaceIds, ['workspace-current']);
      expect(calls, hasLength(1));
      expect(calls.single.workspaceId, 'workspace-current');
      expect(calls.single.connector, same(_connector));
      expect(calls.single.tool.slug, 'search');
      expect(calls.single.arguments, {
        'query': 'find a record',
        'credentialId': 'service:one',
      });
    });

    test('blocks execution when no enabled Connection matches', () async {
      var ran = false;
      final usecase = _usecase(
        connections: const [],
        onRun:
            ({
              required workspaceId,
              required connector,
              required tool,
              required arguments,
            }) async {
              ran = true;

              return 'should not run';
            },
      );

      await expectLater(
        () => usecase.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': {'query': 'record'},
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (error) => error.responseRaw,
            'message',
            contains('No enabled Connection'),
          ),
        ),
      );
      expect(ran, isFalse);
    });

    test('requires an explicit Connection when several match', () async {
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
          AppSkillCredentialCandidate(id: 'service:two', name: 'Personal'),
        ],
      );

      await expectLater(
        () => usecase.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': {'query': 'record'},
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (error) => error.responseRaw,
            'message',
            contains('Choose a Connection'),
          ),
        ),
      );
    });

    test('checks the current revision and schema before execution', () async {
      var ran = false;
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
        ],
        onRun:
            ({
              required workspaceId,
              required connector,
              required tool,
              required arguments,
            }) async {
              ran = true;

              return 'done';
            },
      );
      final discoveredTools = _objectMap(
        await usecase.call(
          workspaceId: 'workspace-current',
          commandName: listConnectorToolsToolName,
          arguments: const {},
        ),
      );
      final currentRevision = _stringField(
        _objectMap(_objectList(discoveredTools['tools']).single),
        'revision',
      );
      final changedContract = _usecase(
        connections: const [],
        connectors: [
          AppSkillDefinition(
            identifier: 'example',
            slug: 'example',
            title: 'Example',
            description: 'Example Connector.',
            content: '',
            tools: [
              AppSkillToolDefinition(
                slug: 'search',
                title: 'Search',
                description: 'Search current records.',
                inputJsonSchema: _tool.inputJsonSchema,
                urlTemplate: _tool.urlTemplate,
              ),
            ],
          ),
        ],
      );

      await expectLater(
        () => usecase.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': {'query': 'record'},
            'revision': 'stale',
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (error) => error.responseRaw,
            'message',
            contains('contract changed'),
          ),
        ),
      );
      await expectLater(
        () => changedContract.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': {'query': 'record'},
            'revision': currentRevision,
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (error) => error.responseRaw,
            'message',
            contains('contract changed'),
          ),
        ),
      );
      await expectLater(
        () => usecase.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': const <String, Object?>{},
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>().having(
            (error) => error.responseRaw,
            'message',
            contains('schema'),
          ),
        ),
      );
      expect(ran, isFalse);
    });

    test('discovers tool contracts and safe Connection labels', () async {
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
        ],
      );

      final tools = _objectMap(
        await usecase.call(
          workspaceId: 'workspace-current',
          commandName: listConnectorToolsToolName,
          arguments: const {},
        ),
      );
      final discovered = _objectMap(_objectList(tools['tools']).single);

      expect(discovered['toolId'], 'connector/example/search');
      expect(discovered['revision'], isA<String>());
      expect(discovered['inputSchema'], _tool.inputJsonSchema);
      expect(discovered['connections'], [
        {'id': 'service:one', 'name': 'Work'},
      ]);
      expect(tools.toString(), isNot(contains('secret-value')));
    });

    test(
      'lists current Connections without exposing credential data',
      () async {
        final usecase = _usecase(
          connections: const [
            AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
          ],
        );

        final result = _objectMap(
          await usecase.call(
            workspaceId: 'workspace-current',
            commandName: listConnectorConnectionsToolName,
            arguments: const {},
          ),
        );

        expect(result['connections'], [
          {
            'id': 'service:one',
            'name': 'Work',
            'connectorIds': ['example'],
          },
        ]);
        expect(result.toString(), isNot(contains('credential')));
        expect(result.toString(), isNot(contains('secret-value')));
      },
    );

    test('replaces executor errors with a safe recoverable result', () async {
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
        ],
        onRun:
            ({
              required workspaceId,
              required connector,
              required tool,
              required arguments,
            }) async {
              throw StateError('request failed with secret-value');
            },
      );

      await expectLater(
        () => usecase.call(
          workspaceId: 'workspace-current',
          commandName: executeConnectorToolName,
          arguments: {
            'toolId': 'connector/example/search',
            'args': {'query': 'record'},
          },
        ),
        throwsA(
          isA<AgentToolExecutionFailure>()
              .having(
                (failure) => failure.responseRaw,
                'responseRaw',
                contains('Connector tool failed'),
              )
              .having(
                (failure) => failure.responseRaw,
                'responseRaw',
                isNot(contains('secret-value')),
              )
              .having(
                (failure) => failure.error.toString(),
                'logged error',
                isNot(contains('secret-value')),
              ),
        ),
      );
    });

    test(
      'redacts failures already wrapped by the shared tool executor',
      () async {
        final usecase = _usecase(
          connections: const [
            AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
          ],
          onRun:
              ({
                required workspaceId,
                required connector,
                required tool,
                required arguments,
              }) async {
                throw AgentToolExecutionFailure(
                  responseRaw: 'secret-value',
                  error: StateError('secret-value'),
                  stackTrace: .current,
                  failurePhase: 'service.execution',
                );
              },
        );

        await expectLater(
          () => usecase.call(
            workspaceId: 'workspace-current',
            commandName: executeConnectorToolName,
            arguments: {
              'toolId': 'connector/example/search',
              'args': {'query': 'record'},
            },
          ),
          throwsA(
            isA<AgentToolExecutionFailure>()
                .having(
                  (failure) => failure.responseRaw,
                  'responseRaw',
                  contains('Connector tool failed'),
                )
                .having(
                  (failure) => failure.responseRaw,
                  'responseRaw',
                  isNot(contains('secret-value')),
                )
                .having(
                  (failure) => failure.error.toString(),
                  'logged error',
                  isNot(contains('secret-value')),
                ),
          ),
        );
      },
    );

    test('executes with the selected current Connection', () async {
      Map<String, dynamic>? calledArguments;
      final usecase = _usecase(
        connections: const [
          AppSkillCredentialCandidate(id: 'service:one', name: 'Work'),
          AppSkillCredentialCandidate(id: 'service:two', name: 'Personal'),
        ],
        onRun:
            ({
              required workspaceId,
              required connector,
              required tool,
              required arguments,
            }) async {
              calledArguments = arguments;

              return 'done';
            },
      );

      final _ = await usecase.call(
        workspaceId: 'workspace-current',
        commandName: executeConnectorToolName,
        arguments: {
          'toolId': 'connector/example/search',
          'args': {'query': 'record'},
          'connectionId': 'service:two',
        },
      );

      expect(calledArguments?['credentialId'], 'service:two');
    });
  });
}

const _connector = AppSkillDefinition(
  identifier: 'example',
  slug: 'example',
  title: 'Example',
  description: 'Example Connector.',
  content: '',
  tools: [_tool],
);

const _tool = AppSkillToolDefinition(
  slug: 'search',
  title: 'Search',
  description: 'Search current records.',
  inputJsonSchema: {
    'type': 'object',
    'properties': {
      'query': {'type': 'string'},
    },
    'required': ['query'],
    'additionalProperties': false,
  },
  urlTemplate: .new(
    template: .new(url: 'https://example.invalid/search'),
    inputs: {},
  ),
  requiresCredential: true,
);

ConnectorCommandUsecase _usecase({
  required List<AppSkillCredentialCandidate> connections,
  List<AppSkillDefinition> connectors = const [_connector],
  ConnectorConnectionsLoader? onLoadConnections,
  ConnectorToolRunner? onRun,
}) => ConnectorCommandUsecase(
  loadConnections: onLoadConnections ?? (_, _) async => connections,
  runTool:
      onRun ??
      ({
        required workspaceId,
        required connector,
        required tool,
        required arguments,
      }) async => 'done',
  connectors: connectors,
);

Map<String, Object?> _objectMap(Object? value) {
  if (value is Map<String, Object?>) return value;

  throw StateError('Expected an object map.');
}

List<Object?> _objectList(Object? value) {
  if (value is List<Object?>) return value;

  throw StateError('Expected an object list.');
}

String _stringField(Map<String, Object?> object, String key) {
  final value = object[key];
  if (value is String) return value;

  throw StateError('Expected a string value.');
}
