import 'package:auravibes_app/features/models/widgets/model_choice_explanation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_app.dart';

void main() {
  for (final locale in [
    (
      code: 'en',
      providerDescription: 'Choose the service or server for your model',
      modelDescription: 'Models can differ in response quality',
      helpLabel: 'Learn about providers and models',
      helpTitle: 'About providers and models',
      helpDetails: 'A provider is the service or server configured',
    ),
    (
      code: 'es',
      providerDescription: 'Elige el servicio o servidor para tu modelo',
      modelDescription: 'Los modelos pueden diferir en la calidad',
      helpLabel: 'Más información sobre proveedores y modelos',
      helpTitle: 'Sobre proveedores y modelos',
      helpDetails: 'Un proveedor es el servicio o servidor configurado',
    ),
  ]) {
    testWidgets('localizes provider choice guidance in ${locale.code}', (
      tester,
    ) async {
      await _expectExplanation(
        tester,
        localeCode: locale.code,
        descriptionKey: 'intro_flow.ai.choose_provider',
        description: locale.providerDescription,
        helpLabel: locale.helpLabel,
        helpTitle: locale.helpTitle,
        helpDetailsPrefix: locale.helpDetails,
      );
    });

    testWidgets('localizes model choice guidance in ${locale.code}', (
      tester,
    ) async {
      await _expectExplanation(
        tester,
        localeCode: locale.code,
        descriptionKey: 'models_screens.model_choice_explanation',
        description: locale.modelDescription,
        helpLabel: locale.helpLabel,
        helpTitle: locale.helpTitle,
        helpDetailsPrefix: locale.helpDetails,
      );
    });
  }
}

Future<void> _expectExplanation(
  WidgetTester tester, {
  required String localeCode,
  required String descriptionKey,
  required String description,
  required String helpLabel,
  required String helpTitle,
  required String helpDetailsPrefix,
}) async {
  final semantics = tester.ensureSemantics();
  addTearDown(semantics.dispose);
  await tester.pumpWidget(
    TestableApp(
      startLocale: Locale(localeCode),
      child: Scaffold(
        body: ModelChoiceExplanation(descriptionKey: descriptionKey),
      ),
    ),
  );
  await tester.pumpAndSettle();
  expect(find.textContaining(description), findsOneWidget);
  expect(find.bySemanticsLabel(helpLabel), findsOneWidget);

  await tester.tap(find.bySemanticsLabel(helpLabel));
  await tester.pumpAndSettle();
  expect(find.text(helpTitle), findsOneWidget);
  expect(find.textContaining(helpDetailsPrefix), findsOneWidget);
}
