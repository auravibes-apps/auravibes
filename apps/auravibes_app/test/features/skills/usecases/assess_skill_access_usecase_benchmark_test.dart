import 'dart:convert';

import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/skill_access_summary.dart';
import 'package:auravibes_app/features/skills/usecases/connector_tool_reference_readiness.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

const _candidateReadDelay = Duration(milliseconds: 5);
const _warmupSamples = 1;
const _measuredSamples = 5;
const _distinctDependencyCounts = [1, 4, 8, 16];

void main() {
  test(
    'compares synthetic serial and batched credential readiness',
    () async {
      final sharedCredentialToolIds = _sharedCredentialToolIds();
      expect(sharedCredentialToolIds, hasLength(greaterThan(1)));

      final workloads = <({String kind, int dependencyCount, List<String> ids})>[
        (
          kind: 'shared-credential',
          dependencyCount: 1,
          ids: sharedCredentialToolIds,
        ),
        for (final dependencyCount in _distinctDependencyCounts)
          (
            kind: 'distinct-connectors',
            dependencyCount: dependencyCount,
            ids: _distinctConnectorToolIds().take(dependencyCount).toList(),
          ),
      ];

      for (final workload in workloads) {
        final serialSamples = <int>[];
        final batchedSamples = <int>[];
        var maxConcurrentBatchedReads = 0;
        for (
          var sample = 0;
          sample < _warmupSamples + _measuredSamples;
          sample++
        ) {
          final serial = await _measureSerial(workload.ids);
          final batched = await _measureBatched(workload.ids);
          expect(serial.candidateReads, workload.ids.length);
          expect(serial.maxConcurrentReads, 1);
          expect(batched.candidateReads, workload.dependencyCount);
          if (batched.maxConcurrentReads > maxConcurrentBatchedReads) {
            maxConcurrentBatchedReads = batched.maxConcurrentReads;
          }
          if (sample >= _warmupSamples) {
            serialSamples.add(serial.elapsedMicroseconds);
            batchedSamples.add(batched.elapsedMicroseconds);
          }
        }
        serialSamples.sort();
        batchedSamples.sort();
        debugPrint(
          jsonEncode({
            'workload': 'skill_credential_readiness',
            'source': 'synthetic-in-memory',
            'networkCalls': 0,
            'modelCalls': 0,
            'kind': workload.kind,
            'dependencyCount': workload.dependencyCount,
            'toolCount': workload.ids.length,
            'candidateReadDelayMs': _candidateReadDelay.inMilliseconds,
            'serialCandidateReadCount': workload.ids.length,
            'batchedCandidateReadCount': workload.dependencyCount,
            'maxConcurrentBatchedReads': maxConcurrentBatchedReads,
            'warmupSamples': _warmupSamples,
            'sampleCount': _measuredSamples,
            'serialMedianElapsedUs':
                serialSamples[serialSamples.length ~/ 2],
            'batchedMedianElapsedUs':
                batchedSamples[batchedSamples.length ~/ 2],
            'serialSamples': serialSamples,
            'batchedSamples': batchedSamples,
          }),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<_ReadinessSample> _measureSerial(List<String> connectorToolIds) async {
  final fixture = _candidateFixture();
  final stopwatch = Stopwatch()..start();
  for (final connectorToolId in connectorToolIds) {
    final ready = await ConnectorToolReferenceReadiness.areReady(
      connectorToolIds: [connectorToolId],
      workspaceId: 'synthetic-workspace',
      credentialCandidates: fixture.usecase,
    );
    expect(ready, isTrue);
  }
  stopwatch.stop();

  return (
    candidateReads: fixture.metrics.candidateReads,
    maxConcurrentReads: fixture.metrics.maxConcurrentReads,
    elapsedMicroseconds: stopwatch.elapsedMicroseconds,
  );
}

Future<_ReadinessSample> _measureBatched(List<String> connectorToolIds) async {
  final fixture = _candidateFixture();
  final stopwatch = Stopwatch()..start();
  final statuses = await ConnectorToolReferenceReadiness.readinessForTools(
    connectorToolIds: connectorToolIds,
    workspaceId: 'synthetic-workspace',
    credentialCandidates: fixture.usecase,
  );
  stopwatch.stop();
  expect(
    statuses,
    everyElement(SkillToolAccessStatus.available),
  );

  return (
    candidateReads: fixture.metrics.candidateReads,
    maxConcurrentReads: fixture.metrics.maxConcurrentReads,
    elapsedMicroseconds: stopwatch.elapsedMicroseconds,
  );
}

_CandidateFixture _candidateFixture() {
  final metrics = _CandidateReadMetrics();
  final usecase = ListConnectorConnectionCandidatesUsecase(
    () => throw StateError('Synthetic benchmark must not access local storage.'),
    cloudServiceConnectionsReader: (_) async {
      metrics.activeReads++;
      metrics.candidateReads++;
      if (metrics.activeReads > metrics.maxConcurrentReads) {
        metrics.maxConcurrentReads = metrics.activeReads;
      }
      await Future<void>.delayed(_candidateReadDelay);
      metrics.activeReads--;

      return [
        for (final connector in connectorDefinitions)
          CloudServiceConnection(
            id: 'synthetic-${connector.identifier}',
            revision: 1,
            name: 'Synthetic connection',
            serviceId: connector.identifier,
            hasSecret: true,
            scope: .workspace,
            kind: 'customHttp',
          ),
      ];
    },
  );

  return (metrics: metrics, usecase: usecase);
}

List<String> _sharedCredentialToolIds() {
  final connector = connectorDefinitions.singleWhere(
    (connector) => connector.identifier == 'brave',
  );
  final tools = connector.tools
      .where((tool) => tool.requiresConnection && tool.urlTemplate != null)
      .toList();
  final sharedDefinition = tools.first.urlTemplate!.credentialDefinitions;
  expect(
    tools.every(
      (tool) =>
          identical(tool.urlTemplate!.credentialDefinitions, sharedDefinition),
    ),
    isTrue,
  );

  return [for (final tool in tools) connectorToolId(connector, tool)];
}

List<String> _distinctConnectorToolIds() {
  final ids = <String>[];
  for (final connector in connectorDefinitions) {
    for (final tool in connector.tools) {
      if (!tool.requiresConnection || tool.urlTemplate == null) continue;
      ids.add(connectorToolId(connector, tool));
      break;
    }
  }
  if (ids.length < _distinctDependencyCounts.last) {
    throw StateError('The synthetic workload needs 16 distinct connectors.');
  }

  return ids;
}

typedef _CandidateFixture = ({
  _CandidateReadMetrics metrics,
  ListConnectorConnectionCandidatesUsecase usecase,
});

typedef _ReadinessSample = ({
  int candidateReads,
  int maxConcurrentReads,
  int elapsedMicroseconds,
});

class _CandidateReadMetrics {
  int activeReads = 0;
  int candidateReads = 0;
  int maxConcurrentReads = 0;
}
