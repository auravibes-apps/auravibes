import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

import 'marionette_run.dart';

void main() {
  test('extracts the VM service URI from Flutter output', () {
    expect(
      extractVmServiceUri(
        'The Flutter DevTools debugger is available at: '
        'http://127.0.0.1:1234/?uri=ws://127.0.0.1:1234/token=/ws',
      ),
      'ws://127.0.0.1:1234/token=/ws',
    );
  });

  test('returns null when Flutter has not printed a VM service URI', () {
    expect(extractVmServiceUri('Building macOS application...'), isNull);
  });

  test('writes the VM service URI atomically with owner-only permissions', () {
    final root = Directory.systemTemp.createTempSync(
      'auravibes-marionette-manifest-',
    );
    addTearDown(() => root.deleteSync(recursive: true));
    final manifestFile = File('${root.path}/instances/agent-a.json');

    writeMarionetteManifest(
      manifestFile: manifestFile,
      instanceId: 'agent-a',
      pid: pid,
      vmServiceUri: 'ws://127.0.0.1:1234/token=/ws',
      startedAt: '2026-09-22T00:00:00.000Z',
    );
    writeMarionetteManifest(
      manifestFile: manifestFile,
      instanceId: 'agent-a',
      pid: pid,
      vmServiceUri: 'ws://127.0.0.1:4321/replacement=/ws',
      startedAt: '2026-09-22T00:00:00.000Z',
    );

    final manifest = jsonDecode(manifestFile.readAsStringSync());
    expect(
      manifest['vmServiceUri'],
      'ws://127.0.0.1:4321/replacement=/ws',
    );
    expect(manifestFile.parent.listSync().map((entry) => entry.path), [
      manifestFile.path,
    ]);
    if (!Platform.isWindows) {
      expect(_modeOf(manifestFile.parent.path), '700');
      expect(_modeOf(manifestFile.path), '600');
    }
  });
}

String _modeOf(String path) {
  final arguments = Platform.isMacOS
      ? ['-f', '%Lp', path]
      : ['-c', '%a', path];
  final result = Process.runSync('stat', arguments);
  if (result.exitCode != 0) {
    throw ProcessException('stat', arguments, '${result.stderr}');
  }

  return '${result.stdout}'.trim();
}
