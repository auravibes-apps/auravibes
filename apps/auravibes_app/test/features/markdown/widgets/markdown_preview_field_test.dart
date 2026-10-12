import 'dart:ui' show CheckedState;

import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
  testWidgets('opens confirmed HTTP and HTTPS links from the preview', (
    tester,
  ) async {
    final launchedUrls = <String>[];
    _mockUrlLauncher(tester, (call) async {
      launchedUrls.add((call.arguments as Map)['url'] as String);

      return true;
    });
    final controller = TextEditingController(
      text:
          '[Open HTTP](http://example.com) '
          '[Open HTTPS](https://example.org/path)',
    );
    addTearDown(controller.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: MarkdownPreviewField(
              controller: controller,
              titleKey: LocaleKeys.markdown_editor_preview_label,
              editKey: LocaleKeys.common_edit,
              emptyKey: LocaleKeys.markdown_editor_empty,
              onEdit: () => fail('Unexpected edit'),
            ),
          ),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Open HTTP'));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('Host: example.com'), findsOneWidget);
    expect(launchedUrls, isEmpty);
    await tester.tap(find.text('Open link'));
    final _ = await tester.pumpAndSettle();

    await tester.tap(find.text('Open HTTPS'));
    final _ = await tester.pumpAndSettle();
    expect(find.textContaining('Host: example.org'), findsOneWidget);
    await tester.tap(find.text('Open link'));
    final _ = await tester.pumpAndSettle();

    expect(launchedUrls, ['http://example.com', 'https://example.org/path']);
  });

  testWidgets('rejects unsafe and malformed link destinations', (tester) async {
    var launchCount = 0;
    _mockUrlLauncher(tester, (_) async {
      launchCount++;

      return true;
    });
    final controller = TextEditingController(
      text:
          '[JavaScript](javascript:alert(1)) '
          '[Data](data:text/html,unsafe) '
          '[Mailto](mailto:docs@example.com) '
          '[File](file:///tmp/unsafe) '
          '[Missing host](https:///missing-host) '
          '[Deceptive](https://accounts.example@attacker.example/sso)',
    );
    addTearDown(controller.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: MarkdownPreviewField(
              controller: controller,
              titleKey: LocaleKeys.markdown_editor_preview_label,
              editKey: LocaleKeys.common_edit,
              emptyKey: LocaleKeys.markdown_editor_empty,
              onEdit: () => fail('Unexpected edit'),
            ),
          ),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    for (final label in [
      'JavaScript',
      'Data',
      'Mailto',
      'File',
      'Missing host',
      'Deceptive',
    ]) {
      await tester.ensureVisible(find.text(label));
      await tester.tap(find.text(label));
      final _ = await tester.pumpAndSettle();
      expect(find.byType(AuraConfirmDialog), findsNothing);
    }

    expect(launchCount, 0);
  });

  testWidgets('preview renders unchecked and checked task items', (
    tester,
  ) async {
    final controller = TextEditingController(
      text: '- [ ] Pending\n- [x] Complete',
    );
    addTearDown(controller.dispose);

    await tester.runAsync(() async {
      await tester.pumpWidget(
        TestableApp(
          child: Scaffold(
            body: MarkdownPreviewField(
              controller: controller,
              titleKey: LocaleKeys.markdown_editor_preview_label,
              editKey: LocaleKeys.common_edit,
              emptyKey: LocaleKeys.markdown_editor_empty,
              onEdit: () => fail('Unexpected edit'),
            ),
          ),
        ),
      );
    });
    final _ = await tester.pumpAndSettle();

    final checkboxes = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == 'Checkbox',
    );
    expect(checkboxes, findsNWidgets(2));
    expect(
      tester.getSemantics(checkboxes.at(0)).flagsCollection.isChecked,
      CheckedState.isFalse,
    );
    expect(
      tester.getSemantics(checkboxes.at(1)).flagsCollection.isChecked,
      CheckedState.isTrue,
    );
  });
}

void _mockUrlLauncher(
  WidgetTester tester,
  Future<Object?> Function(MethodCall call) handler,
) {
  const channel = MethodChannel('plugins.flutter.io/url_launcher');
  final messenger = tester.binding.defaultBinaryMessenger
    ..setMockMethodCallHandler(channel, handler);
  addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
}
