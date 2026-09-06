import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:auravibes_app/features/chats/agent_adapters/aura_chat_catalog_adapter.dart';
import 'package:auravibes_app/features/chats/agent_adapters/chat_catalog_image_adapter.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:genui/genui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  test('both catalogs advertise implemented image properties', () {
    for (final catalog in [auraChatResponseCatalog(), auraChatFormCatalog()]) {
      final image = catalog.items.singleWhere((item) => item.name == 'Image');
      final properties = image.dataSchema.value['properties']! as Map;
      expect(properties.keys, containsAll(['label', 'width', 'height']));
      expect((properties['variant'] as Map)['enum'], [
        'normal',
        'circle',
        'avatar',
      ]);
      expect((properties['width'] as Map)['maximum'], 1024);
      expect((properties['height'] as Map)['minimum'], 1);
      final example =
          (jsonDecode(image.exampleData.single()) as List).single as Map;
      expect(example['variant'], 'normal');
    }
  });

  for (final variant in ChatCatalogImageVariant.values) {
    testWidgets('$variant has real geometry in unbounded layout', (
      tester,
    ) async {
      await _pump(
        tester,
        Row(
          children: [ChatCatalogImage(url: '', variant: variant)],
        ),
      );
      final size = tester.getSize(find.byType(ChatCatalogImage));
      expect(size, switch (variant) {
        ChatCatalogImageVariant.normal => const Size(240, 160),
        ChatCatalogImageVariant.circle => const Size(240, 240),
        ChatCatalogImageVariant.avatar => const Size(48, 48),
      });
      expect(
        find.byType(ClipOval),
        variant == ChatCatalogImageVariant.normal
            ? findsNothing
            : findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('URL validation loading is localized before failure', (
    tester,
  ) async {
    for (final locale in ['en', 'es']) {
      final child = ValueNotifier<Widget>(const SizedBox.shrink());
      addTearDown(child.dispose);
      await _pump(
        tester,
        ValueListenableBuilder<Widget>(
          valueListenable: child,
          builder: (_, value, _) => value,
        ),
        locale: locale,
      );
      child.value = const ChatCatalogImage(url: 'https://127.0.0.1/a.png');
      await tester.pump();
      expect(
        find.textContaining(
          locale == 'en' ? 'Loading image' : 'Cargando imagen',
        ),
        findsOneWidget,
      );
      final _ = await tester.pumpAndSettle();
      expect(
        find.text(
          locale == 'en' ? 'Image unavailable' : 'Imagen no disponible',
        ),
        findsOneWidget,
      );
    }
  });

  testWidgets('unsafe and empty URLs fail visibly without a network image', (
    tester,
  ) async {
    for (final url in [
      '',
      'http://example.com/a.png',
      'https://127.0.0.1/a.png',
      'https://10.0.0.1/a.png',
      'https://[::1]/a.png',
      'https://user:secret@example.com/a.png',
    ]) {
      await _pump(tester, ChatCatalogImage(url: url));
      expect(find.text('Image unavailable'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('dimensions stay finite and obey small parent constraints', (
    tester,
  ) async {
    for (final width in [double.infinity, double.nan, -5.0, 100000.0]) {
      await _pump(
        tester,
        SizedBox(
          width: 80,
          height: 60,
          child: ChatCatalogImage(url: '', width: width, height: 100000),
        ),
      );
      final clip = tester.getSize(find.byType(ClipRect).last);
      expect(clip.width, inInclusiveRange(1, 80));
      expect(clip.height, 60);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('network failure uses localized status despite image label', (
    tester,
  ) async {
    await _pump(
      tester,
      const ChatCatalogImage(
        url: 'https://8.8.8.8/image.png',
        label: 'Landscape',
      ),
      locale: 'es',
    );
    await tester.pump(const Duration(seconds: 21));
    final future = tester
        .widget<FutureBuilder<Uint8List>>(find.byType(FutureBuilder<Uint8List>))
        .future;
    await tester.runAsync(() async {
      await expectLater(future, throwsA(isA<Exception>()));
    });
    final _ = await tester.pumpAndSettle();
    expect(find.text('Imagen no disponible'), findsOneWidget);
    expect(find.bySemanticsLabel('Imagen no disponible'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('bound URL and label update independently of variant', (
    tester,
  ) async {
    final model = InMemoryDataModel();
    addTearDown(model.dispose);
    final dataContext = DataContext(model, DataPath('/'))
      ..update(DataPath('/url'), 'https://8.8.8.8/image.png')
      ..update(DataPath('/label'), 'Landscape');
    final item = auraChatFormCatalog().items.singleWhere(
      (i) => i.name == 'Image',
    );
    await _pump(
      tester,
      Builder(
        builder: (context) => item.widgetBuilder(
          CatalogItemContext(
            data: const {
              'url': {'path': '/url'},
              'label': {'path': '/label'},
              'variant': 'circle',
              'fit': 'contain',
              'width': 100,
              'height': 80,
            },
            id: 'image',
            type: 'Image',
            buildChild: (_, [_]) => const SizedBox.shrink(),
            dispatchEvent: (_) => fail('Image must not dispatch actions'),
            buildContext: context,
            dataContext: dataContext,
            getComponent: (_) => null,
            getCatalogItem: (_) => null,
            surfaceId: 'test',
            reportError: (_, _) => fail('Image builder failed'),
          ),
        ),
      ),
    );
    final image = tester.widget<ChatCatalogImage>(
      find.byType(ChatCatalogImage),
    );
    expect(image.label, 'Landscape');
    expect(image.fit, BoxFit.contain);
    expect(tester.getSize(find.byType(ClipOval)), const Size(80, 80));
    dataContext.update(DataPath('/label'), 'Updated landscape');
    final _ = await tester.pumpAndSettle();
    expect(
      tester.widget<ChatCatalogImage>(find.byType(ChatCatalogImage)).label,
      'Updated landscape',
    );
    dataContext.update(DataPath('/url'), 'https://127.0.0.1/private.png');
    final _ = await tester.pumpAndSettle();
    expect(find.byType(AuraImage), findsNothing);
    expect(find.bySemanticsLabel('Image unavailable'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester,
  Widget child, {
  String locale = 'en',
}) async {
  await tester.pumpWidget(
    EasyLocalization(
      key: ValueKey(locale),
      child: Builder(
        builder: (context) => MaterialApp(
          home: Scaffold(body: child),
          locale: context.locale,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
        ),
      ),
      supportedLocales: const [Locale('en'), Locale('es')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: Locale(locale),
      assetLoader: const _Translations(),
      saveLocale: false,
    ),
  );
  final _ = await tester.pumpAndSettle();
}

class _Translations extends AssetLoader {
  const new();

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async =>
      jsonDecode(File('$path/${locale.languageCode}.json').readAsStringSync())
          as Map<String, dynamic>;
}
