import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('opens URI with url launcher', () async {
    MethodCall? launchCall;
    messenger.setMockMethodCallHandler(channel, (methodCall) async {
      launchCall = methodCall;

      return true;
    });

    final uri = Uri.parse('https://auth.openai.com/codex/device');
    await openSystemBrowser(uri);

    expect(launchCall?.method, 'launch');
    expect(launchCall?.arguments, containsPair('url', uri.toString()));
  });

  test('throws when url launcher cannot open URI', () {
    messenger.setMockMethodCallHandler(channel, (_) => Future.value(false));

    final uri = Uri.parse('https://auth.openai.com/codex/device');

    expect(openSystemBrowser(uri), throwsException);
  });
}
