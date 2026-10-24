import 'dart:async';

import 'package:async/async.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  test(
    'lost response remains uncertain across executor restart and blocks retry',
    () async {
      final journal = _Journal();
      var effects = 0;
      Future<UrlResponse> provider() async {
        effects++;
        throw TimeoutException('secret provider detail');
      }

      final first = await ConnectorWriteExecutor(journal).call(
        operationId: 'write-1',
        requestDigest: 'workspace/tool/connection/arguments',
        execute: provider,
      );
      final retry = await ConnectorWriteExecutor(journal).call(
        operationId: 'write-2',
        requestDigest: 'workspace/tool/connection/arguments',
        execute: provider,
      );
      expect(first.outcome, ConnectorWriteOutcome.uncertain);
      expect(retry.outcome, ConnectorWriteOutcome.uncertain);
      expect(retry.operationId, 'write-1');
      expect(effects, 1);
      expect(
        first.toJson().toString(),
        isNot(contains('secret provider detail')),
      );
    },
  );
  test(
    'completed replay sends once; new intentional operation may send again',
    () async {
      final journal = _Journal();
      var sends = 0;
      Future<UrlResponse> provider() async {
        sends++;
        return const UrlResponse(
          statusCode: 201,
          body: 'created',
          headers: {},
          elapsed: Duration.zero,
        );
      }

      Future<ConnectorWriteReceipt> run(String id) => ConnectorWriteExecutor(
        journal,
      ).call(operationId: id, requestDigest: 'same-input', execute: provider);
      expect((await run('create-1')).statusCode, 201);
      expect((await run('create-1')).outcome, ConnectorWriteOutcome.completed);
      expect(sends, 1);
      expect((await run('create-2')).outcome, ConnectorWriteOutcome.completed);
      expect(sends, 2);
    },
  );

  test(
    'provider reconciliation records result without resending unknown write',
    () async {
      final journal = _Journal();
      var sends = 0;
      Future<UrlResponse> provider() async {
        sends++;
        throw TimeoutException('lost response after provider committed');
      }

      final executor = ConnectorWriteExecutor(journal);
      await executor.call(
        operationId: 'write',
        requestDigest: 'request',
        execute: provider,
      );
      final reconciled = await executor.call(
        operationId: 'write',
        requestDigest: 'request',
        execute: provider,
        reconcile: (receipt) async => ConnectorWriteReceipt(
          operationId: receipt.operationId,
          requestDigest: receipt.requestDigest,
          outcome: ConnectorWriteOutcome.completed,
          statusCode: 201,
        ),
      );
      expect(reconciled.outcome, ConnectorWriteOutcome.completed);
      expect(sends, 1);
      expect(
        (await executor.call(
          operationId: 'write',
          requestDigest: 'request',
          execute: provider,
        )).outcome,
        ConnectorWriteOutcome.completed,
      );
      expect(sends, 1);
    },
  );

  test('same operation cannot execute different inputs', () async {
    final journal = _Journal();
    var sends = 0;
    Future<UrlResponse> provider() async {
      sends++;
      return const UrlResponse(
        statusCode: 422,
        body: 'invalid',
        headers: {},
        elapsed: Duration.zero,
      );
    }

    final executor = ConnectorWriteExecutor(journal);
    expect(
      (await executor.call(
        operationId: 'write',
        requestDigest: 'original',
        execute: provider,
      )).outcome,
      ConnectorWriteOutcome.failed,
    );
    await expectLater(
      executor.call(
        operationId: 'write',
        requestDigest: 'edited',
        execute: provider,
      ),
      throwsFormatException,
    );
    expect(sends, 1);
  });
  test('receipt persistence failure keeps applied write uncertain '
      'and blocks retry', () async {
    final journal = _Journal()..failSave = true;
    var effects = 0;
    Future<UrlResponse> provider() async {
      effects++;
      return const UrlResponse(
        statusCode: 201,
        body: 'created',
        headers: {},
        elapsed: Duration.zero,
      );
    }

    final executor = ConnectorWriteExecutor(journal);
    final first = await executor.call(
      operationId: 'write',
      requestDigest: 'request',
      execute: provider,
    );
    expect(first.outcome, ConnectorWriteOutcome.uncertain);
    expect(
      (await executor.call(
        operationId: 'retry',
        requestDigest: 'request',
        execute: provider,
      )).outcome,
      ConnectorWriteOutcome.uncertain,
    );
    expect(effects, 1);
  });

  test('invalid schema does not claim a write or send a request', () async {
    final journal = _Journal();
    var sends = 0;
    final executor = ConnectorToolTemplateExecutor(
      const ResolveConnectorRequestTemplate(),
      (_) {
        sends++;
        return CancelableOperation.fromFuture(
          Future.value(
            const UrlResponse(
              statusCode: 201,
              body: 'created',
              headers: {},
              elapsed: Duration.zero,
            ),
          ),
        );
      },
    );
    const tool = ConnectorToolDefinition(
      slug: 'create',
      title: 'Create',
      description: '',
      urlTemplate: ConnectorToolRequestTemplate(
        template: ConnectorRequestTemplate(
          url: 'https://example.com/records',
          method: UrlRequestMethod.post,
        ),
        inputs: {},
      ),
    );
    Future<Object?> run(Map<String, dynamic> inputs) =>
        ConnectorRequestExecution(
          executor: executor,
          connector: const ConnectorDefinition(
            identifier: 'fixture',
            title: 'Fixture',
            description: '',
          ),
          tool: tool,
          inputs: inputs,
          credentials: {},
          connectionId: '',
          operationId: 'write',
          journal: journal,
        ).call();
    await expectLater(run({'unexpected': true}), throwsFormatException);
    expect(sends, 0);
    expect(await run({}), containsPair('outcome', 'completed'));
    expect(sends, 1);
  });

  test(
    'HTTP read rejection is failed rather than a successful error body',
    () async {
      final executor = ConnectorToolTemplateExecutor(
        const ResolveConnectorRequestTemplate(),
        (_) => CancelableOperation.fromFuture(
          Future.value(
            const UrlResponse(
              statusCode: 403,
              body: 'synthetic-secret',
              headers: {},
              elapsed: Duration.zero,
            ),
          ),
        ),
      );
      const tool = ConnectorToolDefinition(
        slug: 'read',
        title: 'Read',
        description: '',
        urlTemplate: ConnectorToolRequestTemplate(
          template: ConnectorRequestTemplate(
            url: 'https://example.com/records',
          ),
          inputs: {},
        ),
      );
      await expectLater(
        ConnectorRequestExecution(
          executor: executor,
          connector: const ConnectorDefinition(
            identifier: 'fixture',
            title: 'Fixture',
            description: '',
          ),
          tool: tool,
          inputs: {},
          credentials: {},
          connectionId: '',
          operationId: '',
          journal: _Journal(),
        ).call(),
        throwsA(
          isA<AgentToolExecutionFailure>()
              .having(
                (failure) => failure.responseRaw,
                'status',
                contains('"statusCode":403'),
              )
              .having(
                (failure) => failure.responseRaw,
                'safe output',
                isNot(contains('synthetic-secret')),
              ),
        ),
      );
    },
  );
  test('accepted HTTP writes need reconciliation', () async {
    for (final code in [202, 207, 500, 408]) {
      final result = await ConnectorWriteExecutor(_Journal()).call(
        operationId: 'async-write',
        requestDigest: 'request',
        execute: () async => UrlResponse(
          statusCode: code,
          body: 'not a final outcome',
          headers: const {},
          elapsed: Duration.zero,
        ),
      );
      expect(result.outcome, ConnectorWriteOutcome.uncertain);
    }
  });
  test(
    'operation ID cannot replay success after the tool target changes',
    () async {
      final journal = _Journal();
      var sends = 0;
      final executor = ConnectorToolTemplateExecutor(
        const ResolveConnectorRequestTemplate(),
        (_) {
          sends++;
          return CancelableOperation.fromValue(
            const UrlResponse(
              statusCode: 201,
              body: 'created',
              headers: {},
              elapsed: Duration.zero,
            ),
          );
        },
      );
      ConnectorToolDefinition tool(String url) => ConnectorToolDefinition(
        slug: 'create',
        title: 'Create',
        description: '',
        urlTemplate: ConnectorToolRequestTemplate(
          template: ConnectorRequestTemplate(
            url: url,
            method: UrlRequestMethod.post,
          ),
          inputs: const {},
        ),
      );
      Future<Object> run(String url) => ConnectorRequestExecution(
        executor: executor,
        connector: const ConnectorDefinition(
          identifier: 'fixture',
          title: 'Fixture',
          description: '',
        ),
        tool: tool(url),
        inputs: const {},
        credentials: const {},
        connectionId: 'same-connection',
        operationId: 'same-operation',
        journal: journal,
      ).call();
      expect(
        await run('https://example.com/original'),
        containsPair('outcome', 'completed'),
      );
      await expectLater(
        run('https://example.com/changed'),
        throwsFormatException,
      );
      expect(sends, 1);
    },
  );
}

class _Journal implements ConnectorWriteJournal {
  final Map<String, ConnectorWriteReceipt> receipts = {};
  bool failSave = false;

  @override
  Future<ConnectorWriteReceipt?> claim(
    String operationId,
    String requestDigest,
  ) async {
    for (final receipt in receipts.values) {
      if (receipt.operationId == operationId ||
          (receipt.requestDigest == requestDigest &&
              receipt.outcome == ConnectorWriteOutcome.uncertain)) {
        return receipt;
      }
    }
    receipts[operationId] = ConnectorWriteReceipt(
      operationId: operationId,
      requestDigest: requestDigest,
      outcome: ConnectorWriteOutcome.uncertain,
    );
    return null;
  }

  @override
  Future<void> save(ConnectorWriteReceipt receipt) async {
    if (failSave) throw StateError('Synthetic storage failure');
    receipts[receipt.operationId] = receipt;
  }
}
