import 'package:test/test.dart';

import 'marionette_cli.dart';

void main() {
  test('accepts the selected local dev manifest', () {
    final manifestJson = <String, dynamic>{
      'instanceId': 'agent-a',
      'pid': 42,
      'appFlavor': 'dev',
      'marionetteEnabled': true,
      'vmServiceUri': 'ws://127.0.0.1:1234/token=/ws',
    };
    final manifest = MarionetteInstanceManifest.fromJson(
      manifestJson,
      expectedInstanceId: 'agent-a',
    );

    expect(manifest.instanceId, 'agent-a');
    expect(manifest.vmServiceUri, 'ws://127.0.0.1:1234/token=/ws');
  });

  test('rejects production or remote manifests', () {
    final production = <String, dynamic>{
      'instanceId': 'agent-a',
      'pid': 42,
      'appFlavor': 'prod',
      'marionetteEnabled': true,
      'vmServiceUri': 'ws://127.0.0.1:1234/ws',
    };
    final remote = <String, dynamic>{
      ...production,
      'appFlavor': 'dev',
      'vmServiceUri': 'wss://production.example/ws',
    };

    expect(
      () => MarionetteInstanceManifest.fromJson(
        production,
        expectedInstanceId: 'agent-a',
      ),
      throwsFormatException,
    );
    expect(
      () => MarionetteInstanceManifest.fromJson(
        remote,
        expectedInstanceId: 'agent-a',
      ),
      throwsFormatException,
    );
  });

  test('rejects a manifest without a selected URI', () {
    final manifestJson = <String, dynamic>{
      'instanceId': 'agent-a',
      'pid': 42,
      'appFlavor': 'dev',
      'marionetteEnabled': true,
      'vmServiceUri': null,
    };
    expect(
      () => MarionetteInstanceManifest.fromJson(
        manifestJson,
        expectedInstanceId: 'agent-a',
      ),
      throwsFormatException,
    );
  });

  test('passes only the manifest URI and rejects CLI routing overrides', () {
    const uri = 'ws://127.0.0.1:1234/token=/ws';
    expect(
      buildMarionetteCliArguments(uri, const ['get-interactive-elements']),
      const [
        'run',
        'marionette_cli:marionette',
        '--uri',
        uri,
        'get-interactive-elements',
      ],
    );
    expect(
      () => MarionetteCliOptions.parse(const [
        '--instance-id',
        'agent-a',
        'tap',
        '--uri',
        uri,
      ]),
      throwsFormatException,
    );
    expect(
      () => MarionetteCliOptions.parse(const [
        '--instance-id',
        'agent-a',
        'list',
      ]),
      throwsFormatException,
    );
    expect(
      () => MarionetteCliOptions.parse(const ['get-interactive-elements']),
      throwsFormatException,
    );
  });
}
