import 'dart:ui' show CheckedState;

import 'package:auravibes_app/features/markdown/widgets/markdown_preview_field.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/test_app.dart';

void main() {
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
