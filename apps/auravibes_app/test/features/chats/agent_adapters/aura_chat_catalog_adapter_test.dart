// ignore_for_file: type=lint, type=warning
import 'dart:convert';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/notifiers/chat_a2ui_runtime.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_engine/auravibes_engine.dart' as engine;
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';

void main() {
  test('every advertised icon has a concrete mapping and aliases', () {
    expect(auraChatIcons.keys.toSet(), engine.a2uiChatIconNames.toSet());
    for (final name in engine.a2uiChatIconNames) {
      final snake = name.replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '_${match[0]!.toLowerCase()}',
      );
      expect(auraChatIconData(name), auraChatIcons[name]);
      expect(auraChatIconData(snake), auraChatIcons[name]);
      expect(auraChatIconData(snake.replaceAll('_', '-')), auraChatIcons[name]);
    }
    expect(auraChatIconData('unknown-demo-icon'), Icons.circle_outlined);
    for (final catalog in [auraChatResponseCatalog(), auraChatFormCatalog()]) {
      final schema = catalog.items
          .singleWhere((item) => item.name == 'Icon')
          .dataSchema
          .value;
      expect(
        ((schema['properties'] as Map)['name'] as Map)['enum'],
        engine.a2uiChatIconNames,
      );
    }
  });

  for (final width in [320.0, 768.0, 1200.0]) {
    for (final form in [false, true]) {
      testWidgets('nested dashboard wraps at $width form=$form', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final mode = form ? 'requiresUserAction' : 'passive';
        final payloads = [
          engine.A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'dashboard',
              'catalogId': form ? auraChatFormCatalogId : auraChatCatalogId,
            },
          }, interactionMode: mode),
          engine.A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'updateComponents': {
              'surfaceId': 'dashboard',
              'components': [
                {
                  'id': 'root',
                  'component': 'Tabs',
                  'activeTab': {'path': '/tab'},
                  'tabs': [
                    {'label': 'Overview', 'content': 'dashboardRow'},
                    {'label': 'Details', 'content': 'details'},
                  ],
                },
                {
                  'id': 'details',
                  'component': 'Text',
                  'text': 'Dashboard details',
                },
                {
                  'id': 'dashboardRow',
                  'component': 'Row',
                  'children': ['icon', 'layout'],
                },
                {'id': 'icon', 'component': 'Icon', 'name': 'dashboard'},
                {
                  'id': 'layout',
                  'component': 'Column',
                  'children': ['description', 'cards'],
                },
                {
                  'id': 'description',
                  'component': 'Text',
                  'text': 'Version 3.2 focuses on the new billing engine, SSO federation, and a redesigned analytics workspace. Three of five epics are code-complete.',
                },
                {
                  'id': 'cards',
                  'component': 'Row',
                  'children': ['a', 'b'],
                },
                {'id': 'a', 'component': 'Card', 'child': 'aText'},
                {'id': 'b', 'component': 'Card', 'child': 'bText'},
                {
                  'id': 'aText',
                  'component': 'Text',
                  'text': 'Sprint completion overview',
                },
                {
                  'id': 'bText',
                  'component': 'Text',
                  'text': 'Time remaining before release freeze',
                },
              ],
            },
          }, interactionMode: mode),
        ];
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(extensions: [AuraTheme.light]),
            home: ListView(
              children: [
                ChatA2uiSurfaceHost.historical(
                  messageId: 'dashboard-message',
                  payloads: payloads,
                ),
              ],
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byIcon(Icons.dashboard), findsOneWidget);
        final description = find.textContaining('Version 3.2 focuses');
        expect(description, findsOneWidget);
        expect(tester.getRect(description).right, lessThanOrEqualTo(width));
        await tester.tap(find.text('Details'));
        await tester.pumpAndSettle();
        expect(find.text('Dashboard details'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
  test('advertises the stable Aura chat catalog and every mapped schema', () {
    final catalog = auraChatResponseCatalog();
    final names = catalog.items.map((item) => item.name).toSet();
    final expected = engine.supportedA2uiChatComponents;

    expect(catalog.catalogId, auraChatCatalogId);
    final prompt = auraChatCatalogSystemPrompt();
    expect(prompt, contains(auraChatCatalogId));
    expect(prompt, contains('CATALOG_SCHEMA_START'));
    expect(names, expected);
    for (final item in catalog.items) {
      final schema = item.dataSchema.value;
      expect(schema['properties'], containsPair('component', isNotNull));
      expect(schema['required'], contains('component'));
    }
    expect(
      catalog.items
          .firstWhere((item) => item.name == 'Button')
          .dataSchema
          .value['properties'],
      isNot(contains('checks')),
    );
    expect(
      catalog.items
          .firstWhere((item) => item.name == 'TextField')
          .dataSchema
          .value['properties'],
      isNot(contains('validationRegexp')),
    );
    final sliderProperties =
        catalog.items
                .firstWhere((item) => item.name == 'Slider')
                .dataSchema
                .value['properties']!
            as Map;
    expect(sliderProperties, containsPair('step', isNotNull));
    expect(sliderProperties, containsPair('precision', isNotNull));
    expect(
      (catalog.toCapabilitiesJson()['components']! as Map).keys,
      containsAll(expected),
    );
  });

  test('separates passive response and required-action catalogs', () {
    final response = auraChatResponseCatalog();
    final form = auraChatFormCatalog();
    final responseButton = response.items.firstWhere(
      (item) => item.name == 'Button',
    );
    final responseTextField = response.items.firstWhere(
      (item) => item.name == 'TextField',
    );
    final responseSlider = response.items.firstWhere(
      (item) => item.name == 'Slider',
    );
    final formSlider = form.items.firstWhere((item) => item.name == 'Slider');
    final responseTabs = response.items.firstWhere(
      (item) => item.name == 'Tabs',
    );
    final formTabs = form.items.firstWhere((item) => item.name == 'Tabs');

    expect(response.catalogId, auraChatCatalogId);
    expect(form.catalogId, auraChatFormCatalogId);
    expect(
      responseButton.dataSchema.value['properties'],
      isNot(contains('action')),
    );
    expect(
      (responseSlider.dataSchema.value['properties']! as Map)['value'],
      contains('oneOf'),
    );
    expect(
      (formSlider.dataSchema.value['properties']! as Map)['value'],
      isNot(contains('oneOf')),
    );
    expect(
      responseTabs.dataSchema.value['required'],
      isNot(contains('activeTab')),
    );
    expect(formTabs.dataSchema.value['required'], contains('activeTab'));
    expect(
      responseTextField.dataSchema.value['properties'],
      isNot(contains('onSubmittedAction')),
    );
    expect(form.items, hasLength(response.items.length));
    expect(auraChatCatalogs().map((catalog) => catalog.catalogId), [
      auraChatCatalogId,
      auraChatFormCatalogId,
    ]);
    expect(auraChatCatalogSystemPrompt(), contains(auraChatFormCatalogId));
  });

  testWidgets('renders text across multiple historical surfaces', (
    tester,
  ) async {
    String payload(String surfaceId, String value, {bool create = false}) =>
        jsonEncode({
          'version': 'v0.9',
          if (create)
            'createSurface': {
              'surfaceId': surfaceId,
              'catalogId': auraChatCatalogId,
            }
          else
            'updateComponents': {
              'surfaceId': surfaceId,
              'components': [
                {'id': 'root', 'component': 'Text', 'text': value},
              ],
            },
        });

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SingleChildScrollView(
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'historical-1',
            payloads: [
              payload('one', '', create: true),
              payload('one', 'First'),
              payload('two', '', create: true),
              payload('two', 'Second'),
            ],
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SingleChildScrollView(
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'historical-1',
            payloads: [
              payload('one', '', create: true),
              payload('one', 'Updated'),
            ],
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('First'), findsNothing);
    expect(find.text('Second'), findsNothing);
    expect(find.text('Updated'), findsOneWidget);
  });

  testWidgets('warns when a historical surface omitted root', (tester) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'rootless',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'rootless',
          'components': [
            {'id': 'message', 'component': 'Text', 'text': 'Recovered'},
          ],
        },
      }),
    ];

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: ChatA2uiSurfaceHost.historical(
            messageId: 'historical-rootless',
            payloads: payloads,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Recovered'), findsNothing);
    expect(find.text('This UI could not be loaded.'), findsOneWidget);
    expect(find.textContaining('issues: missingRoot'), findsOneWidget);
  });

  testWidgets('shows and copies a live safe diagnostic immediately', (
    tester,
  ) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);
    runtime
      ..addMessageJson(
        jsonEncode({
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatCatalogId,
          },
        }),
      )
      ..addMessageJson(
        jsonEncode({
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'Preview'},
            ],
          },
        }),
      )
      ..commitCurrentMessage();

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: ChatA2uiSurfaceHost.live(
            runtime: runtime,
            messageId: 'assistant-1',
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {'id': 'root', 'component': 'Text', 'text': 'Invalid update'},
            ],
          },
        },
      }),
    );
    await tester.pump();

    expect(find.text('This UI could not be loaded.'), findsOneWidget);
    expect(
      find.textContaining('issues: invalidInteractionMode'),
      findsOneWidget,
    );

    await tester.tap(find.byIcon(Icons.copy_outlined));
    await tester.pump();
    expect(copiedText, contains('surface: assistant-1:main'));
    expect(copiedText, contains('issues: invalidInteractionMode'));
    expect(copiedText, contains('UI structure:'));
    expect(copiedText, contains('"component": "Text"'));
    expect(find.byIcon(Icons.check), findsOneWidget);
  });

  testWidgets('form slider updates surface data and shows trusted submit', (
    tester,
  ) async {
    final runtime = ChatA2uiRuntime(
      conversationId: 'conversation-1',
      enabled: true,
    )..bindMessage('assistant-1');
    addTearDown(runtime.dispose);

    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'createSurface': {
            'surfaceId': 'main',
            'catalogId': auraChatFormCatalogId,
          },
        },
      }),
    );
    runtime.addMessageJson(
      jsonEncode({
        'protocolVersion': 'v1',
        'interactionMode': 'requiresUserAction',
        'message': {
          'version': 'v0.9',
          'updateComponents': {
            'surfaceId': 'main',
            'components': [
              {
                'id': 'root',
                'component': 'Slider',
                'label': 'Amount',
                'value': {'path': '/amount'},
                'min': 0,
                'max': 100,
                'step': 5,
                'precision': 2,
              },
            ],
          },
        },
      }),
    );
    runtime.commitCurrentMessage();
    runtime.controller
        .contextFor('assistant-1:main')
        .dataModel
        .update(DataPath('/amount'), 20.0);
    expect(runtime.surfaceIdsFor('assistant-1'), ['assistant-1:main']);
    expect(runtime.isReadySurface('assistant-1', 'assistant-1:main'), isTrue);
    expect(runtime.messagesFor('assistant-1'), hasLength(2));

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: SizedBox(
            width: 320,
            child: ChatA2uiSurfaceHost.message(
              runtime: runtime,
              messageId: 'assistant-1',
              payloads: runtime.messagesFor('assistant-1'),
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(AuraLabeledSlider), findsOneWidget);
    expect(find.byType(AuraSlider), findsOneWidget);
    expect(tester.widget<AuraSlider>(find.byType(AuraSlider)).step, 5);
    expect(tester.widget<AuraSlider>(find.byType(AuraSlider)).precision, 2);
    expect(find.text('Amount'), findsOneWidget);
    expect(find.text('20.00'), findsOneWidget);
    expect(find.text('0.00'), findsOneWidget);
    expect(find.text('100.00'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('a2ui_submit_assistant-1:main')),
      findsOneWidget,
    );
    await tester.drag(find.byType(AuraSlider), const Offset(100, 0));

    expect(
      runtime.controller
          .contextFor('assistant-1:main')
          .dataModel
          .getValue<double>(DataPath('/amount')),
      greaterThan(20),
    );
  });

  testWidgets('read-only slider restores its data-model value', (tester) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'slider',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'slider',
          'components': [
            {
              'id': 'root',
              'component': 'Slider',
              'label': 'Score',
              'value': {'path': '/score'},
              'min': 0,
              'max': 100,
            },
          ],
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': 'slider',
          'path': '/score',
          'value': 75,
        },
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SizedBox(
          width: 320,
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'historical-slider',
            payloads: payloads,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.byType(AuraLabeledSlider), findsOneWidget);
    expect(find.text('Score'), findsOneWidget);
    expect(find.text('75.00'), findsOneWidget);
    expect(tester.getSemantics(find.byType(AuraSlider)).value, '75.0');
  });

  testWidgets('read-only slider renders a literal value', (tester) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'slider',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'slider',
          'components': [
            {
              'id': 'root',
              'component': 'Slider',
              'label': 'Utilization',
              'value': 74,
              'min': 0,
              'max': 100,
              'precision': 0,
            },
          ],
        },
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SizedBox(
          width: 320,
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'literal-slider',
            payloads: payloads,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('74'), findsOneWidget);
    expect(find.text('0'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
  });

  testWidgets('row stretch is safe in an unbounded chat surface', (
    tester,
  ) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'dashboard',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'dashboard',
          'components': [
            {
              'id': 'root',
              'component': 'Row',
              'children': ['first', 'second'],
              'align': 'stretch',
            },
            {'id': 'first', 'component': 'Card', 'child': 'first-text'},
            {'id': 'first-text', 'component': 'Text', 'text': 'First'},
            {'id': 'second', 'component': 'Card', 'child': 'second-text'},
            {'id': 'second-text', 'component': 'Text', 'text': 'Second'},
          ],
        },
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: ListView(
          children: [
            ChatA2uiSurfaceHost.historical(
              messageId: 'dashboard-message',
              payloads: payloads,
            ),
          ],
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Second'), findsOneWidget);
  });

  testWidgets('row keeps Spacer and FlexItem inside a Flex', (tester) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'flex-row',
          'catalogId': auraChatCatalogId,
        },
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'flex-row',
          'components': [
            {
              'id': 'root',
              'component': 'Row',
              'children': ['leading', 'flex-item', 'spacer', 'trailing'],
            },
            {'id': 'leading', 'component': 'Text', 'text': 'Leading'},
            {'id': 'flex-item', 'component': 'FlexItem', 'child': 'middle'},
            {'id': 'middle', 'component': 'Text', 'text': 'Middle'},
            {'id': 'spacer', 'component': 'Spacer'},
            {'id': 'trailing', 'component': 'Text', 'text': 'Trailing'},
          ],
        },
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SizedBox(
          width: 320,
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'flex-row-message',
            payloads: payloads,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Leading'), findsOneWidget);
    expect(find.text('Middle'), findsOneWidget);
    expect(find.text('Trailing'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('passive tabs remain locally interactive', (tester) async {
    final payloads = [
      jsonEncode({
        'version': 'v0.9',
        'createSurface': {'surfaceId': 'tabs', 'catalogId': auraChatCatalogId},
      }),
      jsonEncode({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'tabs',
          'components': [
            {
              'id': 'root',
              'component': 'Tabs',
              'tabs': [
                {'label': 'Overview', 'content': 'overview'},
                {'label': 'Alerts', 'content': 'alerts'},
              ],
            },
            {'id': 'overview', 'component': 'Text', 'text': 'Overview content'},
            {'id': 'alerts', 'component': 'Text', 'text': 'Alerts content'},
          ],
        },
      }),
    ];

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: SizedBox(
          width: 320,
          child: ChatA2uiSurfaceHost.historical(
            messageId: 'tabs-message',
            payloads: payloads,
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Overview content'), findsOneWidget);
    await tester.tap(find.text('Alerts'));
    await tester.pump();
    expect(find.text('Alerts content'), findsOneWidget);
  });

  testWidgets('renders the extended catalog components', (tester) async {
    final payloads = [
      engine.A2uiChatContract.encodeEnvelope({
        'version': 'v0.9',
        'createSurface': {
          'surfaceId': 'extended',
          'catalogId': auraChatFormCatalogId,
        },
      }, interactionMode: 'requiresUserAction'),
      engine.A2uiChatContract.encodeEnvelope({
        'version': 'v0.9',
        'updateDataModel': {
          'surfaceId': 'extended',
          'path': '/',
          'value': {'rating': 3, 'tags': <String>[]},
        },
      }, interactionMode: 'requiresUserAction'),
      engine.A2uiChatContract.encodeEnvelope({
        'version': 'v0.9',
        'updateComponents': {
          'surfaceId': 'extended',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': [
                'form',
                'alert',
                'stat',
                'link',
                'tooltip',
                'accordion',
                'stepper',
                'timeline',
                'skeleton',
                'grid',
                'wrap',
                'flex-row',
                'rating',
                'tags',
                'code',
                'key-value',
                'section',
              ],
            },
            {'id': 'form', 'component': 'Form', 'child': 'fieldset'},
            {
              'id': 'fieldset',
              'component': 'Fieldset',
              'legend': 'Details',
              'description': 'Form description',
              'child': 'form-content',
            },
            {'id': 'form-content', 'component': 'Text', 'text': 'Form content'},
            {
              'id': 'alert',
              'component': 'Alert',
              'title': 'Heads up',
              'description': 'Alert description',
              'icon': 'info',
              'tone': 'info',
            },
            {
              'id': 'stat',
              'component': 'Stat',
              'value': '42',
              'label': 'Open items',
              'delta': '+3',
              'icon': 'trendingUp',
              'tone': 'success',
            },
            {
              'id': 'link',
              'component': 'Link',
              'label': 'Read more',
              'semanticLabel': 'Read details',
              'href': 'https://example.com',
            },
            {
              'id': 'tooltip',
              'component': 'Tooltip',
              'message': 'More information',
              'child': 'tooltip-content',
            },
            {
              'id': 'tooltip-content',
              'component': 'Text',
              'text': 'Tooltip content',
            },
            {
              'id': 'accordion',
              'component': 'Accordion',
              'expanded': [0],
              'items': [
                {'title': 'Details', 'content': 'accordion-content'},
              ],
            },
            {
              'id': 'accordion-content',
              'component': 'Text',
              'text': 'Accordion content',
            },
            {
              'id': 'stepper',
              'component': 'Stepper',
              'steps': [
                {
                  'title': 'Started',
                  'description': 'The work began.',
                  'state': 'complete',
                },
                {'title': 'Review', 'state': 'current'},
                {'title': 'Blocked', 'state': 'error'},
                {'title': 'Queued', 'state': 'pending'},
              ],
            },
            {
              'id': 'timeline',
              'component': 'Timeline',
              'entries': [
                {
                  'title': 'Created',
                  'description': 'Created description',
                  'time': 'Today',
                  'tone': 'primary',
                },
                {'title': 'Updated', 'tone': 'success'},
              ],
            },
            {
              'id': 'skeleton',
              'component': 'Skeleton',
              'width': 24,
              'height': 24,
              'shape': 'circle',
              'label': 'Loading',
            },
            {
              'id': 'grid',
              'component': 'Grid',
              'minimumItemWidth': 120,
              'gap': 'lg',
              'children': ['grid-content'],
            },
            {'id': 'grid-content', 'component': 'Text', 'text': 'Grid content'},
            {
              'id': 'wrap',
              'component': 'Wrap',
              'gap': 'xs',
              'children': ['wrap-content'],
            },
            {'id': 'wrap-content', 'component': 'Text', 'text': 'Wrap content'},
            {
              'id': 'flex-row',
              'component': 'Row',
              'children': ['flex-item', 'spacer', 'flex-content'],
            },
            {
              'id': 'flex-item',
              'component': 'FlexItem',
              'flex': 2,
              'fit': 'tight',
              'child': 'flex-item-content',
            },
            {
              'id': 'flex-item-content',
              'component': 'Text',
              'text': 'Flexible content',
            },
            {'id': 'spacer', 'component': 'Spacer', 'size': 12, 'flex': 2},
            {
              'id': 'flex-content',
              'component': 'Text',
              'text': 'Trailing content',
            },
            {
              'id': 'rating',
              'component': 'Rating',
              'value': {'path': '/rating'},
              'max': 5,
              'label': 'Rating',
            },
            {
              'id': 'tags',
              'component': 'TagInput',
              'value': {'path': '/tags'},
              'label': 'Tags',
              'maxSelections': 3,
            },
            {
              'id': 'code',
              'component': 'CodeBlock',
              'code': 'print("Hello")',
              'language': 'dart',
              'label': 'Example code',
            },
            {
              'id': 'key-value',
              'component': 'KeyValue',
              'entries': [
                {'label': 'Status', 'value': 'Ready'},
              ],
            },
            {
              'id': 'section',
              'component': 'Section',
              'title': 'Summary',
              'description': 'Section description',
              'child': 'section-content',
            },
            {
              'id': 'section-content',
              'component': 'Text',
              'text': 'Section content',
            },
          ],
        },
      }, interactionMode: 'requiresUserAction'),
    ];

    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
        child: MaterialApp(
          theme: ThemeData(extensions: [AuraTheme.light]),
          home: Scaffold(
            body: SingleChildScrollView(
              child: SizedBox(
                width: 800,
                child: ChatA2uiSurfaceHost.historical(
                  messageId: 'extended-message',
                  payloads: payloads,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(find.text('Form content'), findsOneWidget);
    expect(find.text('Accordion content'), findsOneWidget);
    expect(find.text('Flexible content'), findsOneWidget);
    expect(find.text('Section content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
