import 'package:auravibes_app/features/chats/widgets/chat_a2ui_surface_host.dart';
import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('Spanish rating and step states come from app labels', (
    tester,
  ) async {
    String envelope(Map<String, Object?> message) =>
        A2uiChatContract.encodeEnvelope({
          'version': a2uiChatWireVersion,
          ...message,
        }, interactionMode: 'requiresUserAction');
    final payloads = [
      envelope({
        'createSurface': {
          'surfaceId': 'localized',
          'catalogId': a2uiChatFormCatalogId,
        },
      }),
      envelope({
        'updateDataModel': {
          'surfaceId': 'localized',
          'path': '/',
          'value': {'rating': 3},
        },
      }),
      envelope({
        'updateComponents': {
          'surfaceId': 'localized',
          'components': [
            {
              'id': 'root',
              'component': 'Column',
              'children': ['stepper', 'rating'],
            },
            {
              'id': 'stepper',
              'component': 'Stepper',
              'steps': [
                {'title': 'Review', 'state': 'current'},
                {'title': 'Done', 'state': 'complete'},
              ],
            },
            {
              'id': 'rating',
              'component': 'Rating',
              'value': {'path': '/rating'},
              'max': 5,
            },
          ],
        },
      }),
    ];
    await tester.runAsync(
      () => tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: ChatA2uiSurfaceHost.historical(
              messageId: 'localized',
              payloads: payloads,
            ),
          ),
          startLocale: const Locale('es'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump();
    expect(
      tester.widget<AuraRating>(find.byType(AuraRating)).semanticValue,
      '3 de 5',
    );
    final steps = tester.widget<AuraStepper>(find.byType(AuraStepper)).steps;
    expect(steps.map((step) => step.semanticLabel), ['Actual', 'Completado']);
  });
}
