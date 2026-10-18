import 'package:auravibes_app/widgets/app_screen.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('keeps body and app bar controls inside either side inset', (
    tester,
  ) async {
    const size = Size(400, 800);
    const inset = 32.0;
    final bodyKey = UniqueKey();
    final leadingKey = UniqueKey();
    final trailingKey = UniqueKey();
    tester.view
      ..devicePixelRatio = 1
      ..physicalSize = size;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final padding in const [
      FakeViewPadding(left: inset),
      FakeViewPadding(right: inset),
    ]) {
      tester.view
        ..padding = padding
        ..viewPadding = padding;
      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: MaterialApp(
            home: AppScreen(
              child: SizedBox.expand(key: bodyKey),
              appBar: _InsetTestAppBar(
                leadingKey: leadingKey,
                trailingKey: trailingKey,
              ),
            ),
            theme: .new(),
          ),
        ),
      );

      final body = tester.getRect(find.byKey(bodyKey));
      expect(body.left, padding.left);
      expect(body.right, size.width - padding.right);
      expect(
        tester.getRect(find.byKey(leadingKey)).left,
        greaterThanOrEqualTo(padding.left),
      );
      expect(
        tester.getRect(find.byKey(trailingKey)).right,
        lessThanOrEqualTo(size.width - padding.right),
      );
    }
  });
}

class const _InsetTestAppBar({
  required final Key leadingKey,
  required final Key trailingKey,
}) extends StatelessWidget implements PreferredSizeWidget {
  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) => Row(
    children: [
      SizedBox(key: leadingKey, width: 48, height: 48),
      const Spacer(),
      SizedBox(key: trailingKey, width: 48, height: 48),
    ],
  );
}
