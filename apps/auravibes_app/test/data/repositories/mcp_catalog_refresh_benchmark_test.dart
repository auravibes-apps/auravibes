import 'dart:convert';
import 'dart:io';

import 'package:auravibes_app/domain/models/mcp_tool_info.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'mcp_catalog_test_support.dart';

void main() {
  for (final backend in ['sqlite-memory', 'sqlite-background-file']) {
    for (final size in [10, 100, 1000]) {
      for (final changedPercent in [0, 10, 100]) {
        test(
          '$backend catalog=$size changed=$changedPercent%',
          () => _measure(backend, size, size * changedPercent ~/ 100),
          timeout: const Timeout(.new(minutes: 2)),
          skip: Platform.environment['AURAVIBES_MCP_CATALOG_BENCHMARK'] == '1'
              ? false
              : 'Set AURAVIBES_MCP_CATALOG_BENCHMARK=1 to measure refresh',
        );
      }
    }
  }
}

Future<void> _measure(String backend, int size, int changedCount) async {
  final fixture = backend == 'sqlite-memory'
      ? McpCatalogFixture.memory()
      : await McpCatalogFixture.backgroundFile();
  addTearDown(fixture.close);
  await fixture.seed(size);
  final original = await fixture.rows();
  final samples = <Map<String, int>>[];
  // Warm up once, then alternate metadata so every changed sample writes.
  for (var sample = 0; sample < 8; sample++) {
    final version = sample.isEven ? 1 : 0;
    final tools = <McpToolInfo>[
      for (var index = 0; index < size; index++)
        McpCatalogFixture.tool(
          index,
          version: index < changedCount ? version : 0,
        ),
    ];
    fixture.metrics.reset();
    final timer = Stopwatch()..start();
    await fixture.refresh(tools);
    timer.stop();
    final metrics = fixture.metrics.snapshot();
    expect(metrics['updateRows'], changedCount);
    expect(metrics['mutationRows'], changedCount);
    expect(metrics['rollbacks'], 0);
    expect(metrics['commits'], 1);
    if (sample > 0) {
      samples.add({'refreshUs': timer.elapsedMicroseconds, ...metrics});
    }
    final stored = await fixture.rows();
    expect(stored, hasLength(size));
    for (var index = 0; index < size; index++) {
      final before = original[index];
      final after = stored[index];
      expect(after.id, before.id);
      expect(after.permissions, before.permissions);
      expect(after.isEnabled, before.isEnabled);
      expect(after.description, tools[index].description);
      expect(after.inputSchema, jsonEncode(tools[index].inputSchema));
      expect(after.outputSchema, jsonEncode(tools[index].outputSchema));
      if (index >= changedCount) expect(after, before);
    }
  }
  final elapsed =
      samples
          .map(
            (sample) => sample['refreshUs'] ?? (throw StateError('No timing')),
          )
          .toList()
        ..sort();
  debugPrint(
    jsonEncode({
      'workload': 'mcp_catalog_refresh',
      'revision':
          Platform.environment['AURAVIBES_MCP_BENCHMARK_REVISION'] ??
          'unrecorded',
      'run':
          Platform.environment['AURAVIBES_MCP_BENCHMARK_RUN'] ?? 'unrecorded',
      'baselineRevision': 'f00fc7b9159cc35713db498ad319200a5ed4052e',
      'backend': backend,
      'os': Platform.operatingSystem,
      'dart': Platform.version.split(' ').first,
      'catalogSize': size,
      'changedTools': changedCount,
      'sampleCount': samples.length,
      'refreshMedianUs': elapsed[elapsed.length ~/ 2],
      'refreshP95Us': elapsed.last,
      'samples': samples,
    }),
  );
}
