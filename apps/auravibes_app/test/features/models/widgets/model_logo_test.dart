// ignore_for_file: no-magic-number
// Required: Tests use numeric fixtures and dimensions.
// ignore_for_file: avoid-returning-widgets
// Required: Widget tests use helpers that build widgets under test.
// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
// ignore_for_file: avoid-unused-parameters
// Required: Test fakes keep interface-compatible parameter names.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Tests keep fixture helpers and fakes top-level.
import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('ModelLogo', () {
    test('constructor stores parameters', () {
      const logo = ModelLogo(modelId: 'test-model');
      expect(logo.modelId, 'test-model');
      expect(logo.height, 20);
      expect(logo.width, isNull);
      expect(logo.svgBuilder, isNull);
      expect(logo.httpClient, isNull);
    });

    test('constructor accepts custom values', () {
      Widget builder(BuildContext context, String url) => Container();
      final client = http.Client();
      final logo = ModelLogo(
        modelId: 'anthropic',
        height: 40,
        width: 40,
        svgBuilder: builder,
        httpClient: client,
      );
      expect(logo.modelId, 'anthropic');
      expect(logo.height, 40);
      expect(logo.width, 40);
      expect(logo.svgBuilder, builder);
      expect(logo.httpClient, client);
    });

    testWidgets('svgBuilder is used when provided', (tester) async {
      const key = Key('custom-builder');
      await tester.pumpWidget(
        _easyLocalizationWrapper(
          child: const ModelLogo(
            modelId: 'openai',
            svgBuilder: _customBuilder,
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets(
      'default SvgPicture.network path when svgBuilder is null',
      (tester) async {
        final mockClient = MockClient((request) async {
          return http.Response(
            '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>',
            200,
          );
        });
        addTearDown(mockClient.close);

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ModelLogo(
                modelId: 'openai',
                httpClient: mockClient,
              ),
            ),
          ),
        );
        final _ = await tester.pumpAndSettle();

        expect(find.byType(ModelLogo), findsOneWidget);
        expect(find.byType(SvgPicture), findsOneWidget);
        expect(find.byType(AuraSpinner), findsNothing);
      },
    );
  });
}

Widget _customBuilder(BuildContext context, String url) {
  return const SizedBox(key: Key('custom-builder'));
}

Widget _easyLocalizationWrapper({required Widget child}) => EasyLocalization(
  child: Builder(
    builder: (context) => MaterialApp(
      home: Scaffold(body: child),
      locale: context.locale,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
    ),
  ),
  supportedLocales: const [Locale('en')],
  path: 'assets/i18n',
  fallbackLocale: const Locale('en'),
  startLocale: const Locale('en'),
  useOnlyLangCode: true,
  useFallbackTranslations: true,
  saveLocale: false,
);
