import 'dart:async';

import 'package:auravibes_app/domain/entities/mcp_elicitation_request.dart';
import 'package:auravibes_app/features/chats/notifiers/mcp_elicitation_notifier.dart';
import 'package:auravibes_app/features/chats/widgets/chat_mcp_elicitation_card.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final _ = TestWidgetsFlutterBinding.ensureInitialized();
  const urlLauncherChannel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });
  tearDown(() {
    messenger.setMockMethodCallHandler(urlLauncherChannel, null);
  });

  testWidgets('validates form and submits edited values with defaults', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Please share your details.',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'name': {
              'type': 'string',
              'title': 'Name',
              'default': 'Ada',
              'pattern': r'^[A-Z][a-z]+$',
            },
            'age': {'type': 'integer', 'default': 4},
            'email': {'type': 'string', 'format': 'email'},
          },
          'required': ['name', 'age', 'email'],
        },
      ),
    );
    await _pumpCard(tester, container);

    expect(
      find.text('Information requested by Example server'),
      findsOneWidget,
    );
    expect(find.text('Please share your details.'), findsOneWidget);
    expect(find.byType(AuraInput), findsNWidgets(3));

    await tester.enterText(find.byType(AuraInput).at(2), 'invalid');
    await tester.tap(find.text('Send response'));
    await tester.pump();
    expect(
      find.textContaining('Some values are missing or invalid'),
      findsOneWidget,
    );
    expect(
      container.read(mcpElicitationProvider('conversation-1')),
      hasLength(1),
    );

    await tester.enterText(find.byType(AuraInput).at(1), '5');
    await tester.enterText(find.byType(AuraInput).at(2), 'ada@example.com');
    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();

    final response = await responseFuture;
    expect(response.action, McpElicitationAction.accept);
    expect(response.content, {
      'name': 'Ada',
      'age': 5,
      'email': 'ada@example.com',
    });
    expect(container.read(mcpElicitationProvider('conversation-1')), isEmpty);
  });

  testWidgets('keeps state with remaining request when earlier card closes', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final firstResponse = _request(
      container,
      const McpElicitationRequest(
        serverName: 'First server',
        message: '',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'default': 'first'},
          },
          'required': ['name'],
        },
      ),
    );
    final secondResponse = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Second server',
        message: '',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'default': 'second'},
          },
          'required': ['name'],
        },
      ),
    );
    await _pumpCard(tester, container);

    await tester.enterText(find.byType(AuraInput).first, 'edited first');
    await tester.enterText(find.byType(AuraInput).last, 'edited second');
    await tester.tap(find.text('Decline').first);
    final _ = await tester.pumpAndSettle();

    expect(find.text('Information requested by Second server'), findsOneWidget);
    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();

    expect((await firstResponse).action, McpElicitationAction.decline);
    expect((await secondResponse).content, {'name': 'edited second'});
  });

  testWidgets('URL opens only after explicit consent and accepts request', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    MethodCall? launchCall;
    messenger.setMockMethodCallHandler(urlLauncherChannel, (call) async {
      launchCall = call;

      return true;
    });
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Sign in to continue.',
        mode: .url,
        url: 'https://example.com/oauth?client=auravibes',
      ),
    );
    await _pumpCard(tester, container);

    expect(
      find.text('External page requested by Example server'),
      findsOneWidget,
    );
    expect(find.text('Host: example.com'), findsOneWidget);
    expect(
      find.text('https://example.com/oauth?client=auravibes'),
      findsOneWidget,
    );
    expect(launchCall, isNull);
    expect(
      container.read(mcpElicitationProvider('conversation-1')),
      hasLength(1),
    );

    await tester.tap(find.text('Open link'));
    final _ = await tester.pumpAndSettle();

    final response = await responseFuture;
    expect(response.action, McpElicitationAction.accept);
    expect(launchCall?.method, 'launch');
    expect(
      (launchCall?.arguments as Map)['url'],
      'https://example.com/oauth?client=auravibes',
    );
  });

  testWidgets('warns when URL host uses Punycode', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Sign in to continue.',
        mode: .url,
        url: 'https://xn--e1afmkfd.xn--p1ai/login',
      ),
    );
    await _pumpCard(tester, container);

    expect(find.textContaining('Punycode'), findsOneWidget);
    expect(find.text('Host: xn--e1afmkfd.xn--p1ai'), findsOneWidget);
    expect(find.text('ASCII host: xn--e1afmkfd.xn--p1ai'), findsOneWidget);
    expect(
      container.read(mcpElicitationProvider('conversation-1')),
      hasLength(1),
    );

    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();

    expect((await responseFuture).action, McpElicitationAction.cancel);
  });

  testWidgets('blocks compatibility-mapped Unicode host', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final unicodeHost = '${String.fromCharCode(0xFF45)}xample.com';
    final url = 'https://$unicodeHost/login';
    final responseFuture = _request(
      container,
      .new(
        serverName: 'Example server',
        message: 'Sign in to continue.',
        mode: .url,
        url: url,
      ),
    );
    await _pumpCard(tester, container);

    expect(
      find.text('Host: ${Uri.decodeComponent(Uri.parse(url).host)}'),
      findsOneWidget,
    );
    expect(find.textContaining('Unicode or Punycode'), findsOneWidget);
    expect(find.textContaining('cannot open this link'), findsOneWidget);
    final openUrlButton = tester
        .widgetList<AuraButton>(find.byType(AuraButton))
        .singleWhere(
          (button) => button.identifier == 'mcp_elicitation_open_url',
        );
    expect(openUrlButton.disabled, isTrue);

    await tester.tap(find.text('Cancel'));
    final _ = await tester.pumpAndSettle();
    expect((await responseFuture).action, McpElicitationAction.cancel);
  });

  testWidgets('accepts URL request after card unmounts during launch', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final launchCompleter = Completer<Object?>();
    messenger.setMockMethodCallHandler(urlLauncherChannel, (call) {
      return launchCompleter.future;
    });
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Sign in to continue.',
        mode: .url,
        url: 'https://example.com/oauth',
      ),
    );
    await _pumpCard(tester, container);

    await tester.tap(find.text('Open link'));
    await tester.pumpWidget(const SizedBox.shrink());
    launchCompleter.complete(true);
    final _ = await tester.pumpAndSettle();

    expect((await responseFuture).action, McpElicitationAction.accept);
  });

  testWidgets('submits empty value for required maxLength zero string', (
    tester,
  ) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'No text allowed.',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'name': {'type': 'string', 'maxLength': 0},
          },
          'required': ['name'],
        },
      ),
    );
    await _pumpCard(tester, container);

    expect(tester.takeException(), isNull);
    expect(find.byType(AuraInput), findsOneWidget);

    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();

    expect((await responseFuture).content, {'name': ''});
  });

  testWidgets('numeric fields ignore string maxLength zero', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Provide a number.',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'age': {'type': 'integer', 'maxLength': 0, 'default': 2},
          },
          'required': ['age'],
        },
      ),
    );
    await _pumpCard(tester, container);

    expect(tester.widget<AuraInput>(find.byType(AuraInput)).enabled, isTrue);

    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();

    expect((await responseFuture).content, {'age': 2});
  });

  testWidgets('shows titles for titled oneOf choices', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Choose a theme.',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'theme': {
              'oneOf': [
                {'const': 'light', 'title': 'Light theme'},
                {'const': 'dark', 'title': 'Dark theme'},
              ],
            },
          },
          'required': ['theme'],
        },
      ),
    );
    await _pumpCard(tester, container);

    await tester.tap(find.byType(AuraDropdownSelector<Object?>));
    final _ = await tester.pumpAndSettle();
    expect(find.text('Dark theme'), findsOneWidget);

    await tester.tap(find.text('Dark theme'));
    final _ = await tester.pumpAndSettle();
    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();

    expect((await responseFuture).content, {'theme': 'dark'});
  });

  testWidgets('keeps URL request pending when launch fails', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    messenger.setMockMethodCallHandler(urlLauncherChannel, (_) async => false);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Sign in to continue.',
        mode: .url,
        url: 'https://example.com/oauth',
      ),
    );
    await _pumpCard(tester, container);

    await tester.tap(find.text('Open link'));
    final _ = await tester.pumpAndSettle();

    expect(
      find.text('Could not open this link. The request remains pending.'),
      findsOneWidget,
    );
    expect(
      container.read(mcpElicitationProvider('conversation-1')),
      hasLength(1),
    );

    await tester.tap(find.text('Cancel'));
    expect((await responseFuture).action, McpElicitationAction.cancel);
  });

  testWidgets('decline and cancel return distinct MCP actions', (tester) async {
    for (final entry in <({String label, McpElicitationAction action})>[
      (label: 'Decline', action: .decline),
      (label: 'Cancel', action: .cancel),
    ]) {
      final container = ProviderContainer();
      final responseFuture = _request(
        container,
        const McpElicitationRequest(
          serverName: 'Example server',
          message: 'Provide a value.',
          mode: .form,
          requestedSchema: {
            'type': 'object',
            'properties': {
              'name': {'type': 'string'},
            },
          },
        ),
      );
      await _pumpCard(tester, container);
      await tester.tap(find.text(entry.label));
      final _ = await tester.pumpAndSettle();

      expect((await responseFuture).action, entry.action);
      container.dispose();
    }
  });

  testWidgets('unsupported form fields cannot be accepted', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Provide a nested value.',
        mode: .form,
        requestedSchema: {
          'type': 'object',
          'properties': {
            'nested': {
              'type': 'object',
              'properties': {
                'value': {'type': 'string'},
              },
            },
          },
        },
      ),
    );
    await _pumpCard(tester, container);

    expect(
      find.text('This request uses fields AuraVibes cannot display.'),
      findsOneWidget,
    );
    await tester.tap(find.text('Send response'));
    final _ = await tester.pumpAndSettle();
    expect(
      container.read(mcpElicitationProvider('conversation-1')),
      hasLength(1),
    );

    await tester.tap(find.text('Cancel'));
    expect((await responseFuture).action, McpElicitationAction.cancel);
  });

  testWidgets('explains unsupported elicitation mode', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final responseFuture = _request(
      container,
      const McpElicitationRequest(
        serverName: 'Example server',
        message: 'Continue on a different interaction mode.',
        mode: .unsupported,
      ),
    );
    await _pumpCard(tester, container);

    expect(
      find.text(
        'This server requested an interaction AuraVibes cannot display.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Cancel'));
    expect((await responseFuture).action, McpElicitationAction.cancel);
  });
}

Future<McpElicitationResponse> _request(
  ProviderContainer container,
  McpElicitationRequest request,
) => container
    .read(mcpElicitationProvider('conversation-1').notifier)
    .request(request);

Future<void> _pumpCard(WidgetTester tester, ProviderContainer container) async {
  final _ = await tester.runAsync(() async {
    await tester.pumpWidget(
      EasyLocalization(
        child: UncontrolledProviderScope(
          container: container,
          child: Builder(
            builder: (context) => Portal(
              child: MaterialApp(
                home: Theme(
                  data: .new(),
                  child: const Material(
                    child: ChatMcpElicitationCard(
                      conversationId: 'conversation-1',
                    ),
                  ),
                ),
                builder: (_, child) => AuraThemeScope(
                  theme: .light,
                  child: AuraLegacyMaterialBridge(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
                locale: context.locale,
                localizationsDelegates: context.localizationDelegates,
                supportedLocales: context.supportedLocales,
              ),
            ),
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  });
  final _ = await tester.pumpAndSettle();
}
