import 'dart:convert';

import 'package:auravibes_app/features/service_connections/models/cloud_service_connection.dart';
import 'package:auravibes_app/features/service_connections/usecases/list_connector_connection_candidates_usecase.dart';
import 'package:auravibes_app/features/skills/models/skill_detail.dart';
import 'package:auravibes_app/features/skills/usecases/assess_skill_access_usecase.dart';
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
    'measures synthetic serial readiness for shared and distinct credentials',
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
        final samples = <int>[];
        for (
          var sample = 0;
          sample < _warmupSamples + _measuredSamples;
          sample++
        ) {
          final measurement = await _measureSerial(workload.ids);
          expect(measurement.candidateReads, workload.ids.length);
          expect(measurement.maxConcurrentReads, 1);
          if (sample >= _warmupSamples) {
            samples.add(measurement.elapsedMicroseconds);
          }
        }
        samples.sort();
        debugPrint(
          jsonEncode({
            'workload': 'skill_credential_readiness_serial_baseline',
            'kind': workload.kind,
            'dependencyCount': workload.dependencyCount,
            'toolCount': workload.ids.length,
            'candidateReadDelayMs': _candidateReadDelay.inMilliseconds,
            'candidateReadCount': workload.ids.length,
            'warmupSamples': _warmupSamples,
            'sampleCount': _measuredSamples,
            'medianElapsedUs': samples[samples.length ~/ 2],
            'samples': samples,
          }),
        );
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}

Future<({int candidateReads, int maxConcurrentReads, int elapsedMicroseconds})>
_measureSerial(List<String> connectorToolIds) async {
  final metrics = _CandidateReadMetrics();
  final candidates = ListConnectorConnectionCandidatesUsecase(
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
  final assess = AssessSkillAccessUsecase(
    connectorReferencesReady: (toolIds) => ConnectorToolReferenceReadiness
        .areReady(
          connectorToolIds: toolIds,
          workspaceId: 'synthetic-workspace',
          credentialCandidates: candidates,
        ),
  );
  final stopwatch = Stopwatch()..start();
  final summary = await assess.call(skill: _skill(connectorToolIds));
  stopwatch.stop();

  expect(summary.tools.map((tool) => tool.id), connectorToolIds);
  expect(
    summary.tools.map((tool) => tool.status),
    everyElement(SkillToolAccessStatus.available),
  );

  return (
    candidateReads: metrics.candidateReads,
    maxConcurrentReads: metrics.maxConcurrentReads,
    elapsedMicroseconds: stopwatch.elapsedMicroseconds,
  );
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

SkillDetail _skill(List<String> connectorToolIds) => SkillDetail(
  id: 'synthetic-skill',
  workspaceId: 'synthetic-workspace',
  source: .user,
  kind: .template,
  title: 'Synthetic skill',
  slug: 'synthetic-skill',
  description: '',
  content: 'Synthetic readiness benchmark.',
  isEnabled: true,
  connectorToolIds: connectorToolIds,
);

class _CandidateReadMetrics {
  int activeReads = 0;
  int candidateReads = 0;
  int maxConcurrentReads = 0;
}
