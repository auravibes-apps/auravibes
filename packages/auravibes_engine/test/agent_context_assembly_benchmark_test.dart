import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:test/test.dart';

void main() {
  test('reports deterministic context sizes across independent runs', () async {
    final libraryUri = await Isolate.resolvePackageUri(
      Uri.parse('package:auravibes_engine/auravibes_engine.dart'),
    );
    final packageRoot = File.fromUri(libraryUri!).parent.parent.path;
    const expectedCounts = [
      [10, 10, 1],
      [50, 50, 5],
      [100, 100, 10],
      [500, 500, 50],
      [1000, 1000, 100],
    ];
    const expectedBytes = [5033, 23665, 46955, 235835, 471935];
    final stableRuns = <List<List<int>>>[];

    for (var run = 0; run < 2; run++) {
      final result = await Process.run(Platform.resolvedExecutable, [
        'benchmark/agent_context_assembly_benchmark.dart',
      ], workingDirectory: packageRoot);
      final reason =
          'Run ${run + 1}\nstdout:\n${result.stdout}'
          '\nstderr:\n${result.stderr}';
      expect(result.exitCode, 0, reason: reason);
      expect(result.stderr, isEmpty, reason: reason);

      final lines = const LineSplitter().convert(result.stdout as String);
      expect(lines, hasLength(6), reason: reason);
      expect(
        lines.first,
        'tools,skills,loaded_skills,median_assembly_us,'
        'serialized_context_bytes',
        reason: reason,
      );
      final stableRows = <List<int>>[];
      var previousBytes = 0;
      for (var index = 0; index < expectedCounts.length; index++) {
        final columns = lines[index + 1].split(',');
        expect(columns, hasLength(5), reason: reason);
        final values = columns.map(int.parse).toList();
        expect(values.take(3), expectedCounts[index], reason: reason);
        expect(values[3], greaterThanOrEqualTo(0), reason: reason);
        expect(values[4], expectedBytes[index], reason: reason);
        expect(values[4], greaterThan(previousBytes), reason: reason);
        previousBytes = values[4];
        stableRows.add([...values.take(3), values[4]]);
      }
      stableRuns.add(stableRows);
    }

    expect(stableRuns[1], stableRuns[0]);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
