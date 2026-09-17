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
}
