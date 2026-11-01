import 'package:auravibes_app/features/models/widgets/model_choice_explanation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  for (final locale in [
    (
      code: 'en',
      providerDescription:
          "Choose which service receives your model's requests",
      modelDescription: 'Models vary in quality',
      helpLabel: 'Learn about providers and models',
      helpTitle: 'About providers and models',
      helpDetails: 'A provider is the service or server configured',
    ),
    (
      code: 'es',
      providerDescription:
          'Elige el servicio que recibe las solicitudes de tu modelo',
      modelDescription: 'Los modelos varían en calidad',
      helpLabel:
          'M${String.fromCharCode(0xe1)}s informaci'
          '${String.fromCharCode(0xf3)}n sobre proveedores y modelos',
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
      child: Scaffold(
        body: ModelChoiceExplanation(descriptionKey: descriptionKey),
      ),
      startLocale: .new(localeCode),
    ),
  );
  final _ = await tester.pumpAndSettle();
  final translationLoaded = await tester.runAsync(() async {
    for (var attempt = 0; attempt < 50; attempt++) {
      if (descriptionKey.tr().contains(description)) return true;
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    return false;
  });
  expect(translationLoaded, isTrue);
  final _ = await tester.pumpAndSettle();
  expect(find.textContaining(description), findsOneWidget);
  expect(find.bySemanticsLabel(helpLabel), findsOneWidget);

  await tester.tap(find.bySemanticsLabel(helpLabel));
  final _ = await tester.pumpAndSettle();
  expect(find.text(helpTitle), findsOneWidget);
  expect(find.textContaining(helpDetailsPrefix), findsOneWidget);
}
