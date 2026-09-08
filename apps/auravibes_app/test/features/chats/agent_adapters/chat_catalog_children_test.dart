import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final component in ['Column', 'List', 'Grid', 'Wrap', 'Row']) {
    for (final source in ['explicit', 'list', 'map']) {
      if (component == 'Row' && source != 'explicit') continue;

      testWidgets('$component renders $source children', (tester) async {
        final payloads = [
          A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'createSurface': {
              'surfaceId': 'children',
              'catalogId': auraChatCatalogId,
            },
          }),
          A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'updateDataModel': {
              'surfaceId': 'children',
              'path': '/',
              'value': {
                'items': source == 'map'
                    ? {
                        'first': {'label': 'Alpha'},
                        'second': {'label': 'Beta'},
                      }
                    : [
                        {'label': 'Alpha'},
                        {'label': 'Beta'},
                      ],
              },
            },
          }),
          A2uiChatContract.encodeEnvelope({
            'version': 'v0.9',
            'updateComponents': {
              'surfaceId': 'children',
              'components': [
                {
                  'id': 'root',
                  'component': component,
                  'children': source == 'explicit'
                      ? ['alpha', 'beta']
                      : {'componentId': 'item', 'path': '/items'},
                },
                if (source == 'explicit') ...[
                  {'id': 'alpha', 'component': 'Text', 'text': 'Alpha'},
                  {'id': 'beta', 'component': 'Text', 'text': 'Beta'},
                ] else
                  {
                    'id': 'item',
                    'component': 'Text',
                    'text': {'path': 'label'},
                  },
              ],
            },
          }),
        ];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: RepaintBoundary(
                key: const Key('surface'),
                child: ListView(
                  children: [
                    ChatA2uiSurfaceHost.historical(
                      messageId: 'message',
                      payloads: payloads,
                    ),
                  ],
                ),
              ),
            ),
            theme: ThemeData(extensions: [AuraTheme.light]),
          ),
        );
        final _ = await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Beta'), findsOneWidget);
        if (component == 'Grid' && source == 'map') {
          await expectLater(
            find.byKey(const Key('surface')),
            matchesGoldenFile('goldens/catalog_children.png'),
          );
        }
      });
    }
  }
}
