import 'dart:async';

import 'package:auravibes_app/features/models/widgets/model_logo.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  const validSvg =
      '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1 1"></svg>';

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
      Widget builder(BuildContext _, String _) => Container();
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
      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          _EasyLocalizationWrapper(
            child: ModelLogo(
              modelId: 'openai',
              svgBuilder: (_, _) => const SizedBox(key: key),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('default SvgPicture.network path when svgBuilder is null', (
      tester,
    ) async {
      var requests = 0;
      final mockClient = MockClient((request) async {
        requests++;

        return http.Response(validSvg, 200);
      });
      addTearDown(mockClient.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelLogo(modelId: 'openai', httpClient: mockClient),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(ModelLogo), findsOneWidget);
      expect(find.byType(SvgPicture), findsOneWidget);
      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(picture.width, 20);
      expect(picture.height, 20);
      expect(picture.imageBuilder, isNotNull);
      expect(find.byType(TweenAnimationBuilder<double>), findsOneWidget);
      expect(find.byType(AuraSpinner), findsNothing);
      expect(requests, 1);
    });

    testWidgets('reserves logo bounds while SVG is loading', (tester) async {
      final response = Completer<http.Response>();
      final mockClient = MockClient((_) => response.future);
      addTearDown(mockClient.close);
      addTearDown(() {
        if (!response.isCompleted) {
          response.complete(http.Response(validSvg, 200));
        }
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ModelLogo(
              modelId: 'loading',
              height: 24,
              width: 32,
              httpClient: mockClient,
            ),
          ),
        ),
      );
      await tester.pump();

      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      expect(picture.width, 32);
      expect(picture.height, 24);
      expect(find.byType(AuraSpinner), findsNothing);
      expect(
        find.descendant(
          of: find.byType(SvgPicture),
          matching: find.byType(ColoredBox),
        ),
        findsOneWidget,
      );
    });

    testWidgets('uses a localized failure icon', (tester) async {
      final mockClient = MockClient((_) async => http.Response(validSvg, 200));
      addTearDown(mockClient.close);

      final _ = await tester.runAsync(
        () => tester.pumpWidget(
          _EasyLocalizationWrapper(
            child: ModelLogo(modelId: 'missing', httpClient: mockClient),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      final picture = tester.widget<SvgPicture>(find.byType(SvgPicture));
      final errorBuilder = picture.errorBuilder;
      expect(errorBuilder, isNotNull);
      if (errorBuilder == null) return;
      final errorView = errorBuilder(
        tester.element(find.byType(SvgPicture)),
        StateError('missing'),
        .empty,
      );
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: errorView)));

      expect(find.byIcon(Icons.broken_image_outlined), findsOneWidget);
      expect(
        tester
            .widget<Semantics>(
              find
                  .ancestor(
                    of: find.byIcon(Icons.broken_image_outlined),
                    matching: find.byType(Semantics),
                  )
                  .first,
            )
            .properties
            .label,
        'No icon',
      );
      expect(find.text('No icon'), findsNothing);
    });

    testWidgets('does not animate when tickers are disabled', (tester) async {
      final mockClient = MockClient((_) async => http.Response(validSvg, 200));
      addTearDown(mockClient.close);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TickerMode(
              enabled: false,
              child: ModelLogo(modelId: 'still', httpClient: mockClient),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(
        tester
            .widget<TweenAnimationBuilder<double>>(
              find.byType(TweenAnimationBuilder<double>),
            )
            .duration,
        Duration.zero,
      );
    });
  });
}

class const _EasyLocalizationWrapper({required final Widget child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
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
  }
}
