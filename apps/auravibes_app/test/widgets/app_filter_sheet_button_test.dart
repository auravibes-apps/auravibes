import 'package:auravibes_app/widgets/app_filter_sheet_button.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('filter sheet sizes to its controls on Duo displays', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in const [Size(466, 678), Size(951, 669)]) {
      tester.view
        ..devicePixelRatio = 1
        ..physicalSize = size;
      await tester.runAsync(
        () => tester.pumpWidget(
          TestableApp(
            child: Scaffold(
              body: Center(
                child: AppFilterSheetButton(
                  activeFilterCount: 0,
                  filtersBuilder: (_) => const Text('Source'),
                  onClearFilters: () =>
                      throw StateError('Unexpected clear filters tap'),
                ),
              ),
            ),
          ),
        ),
      );
      final _ = await tester.pumpAndSettle();

      expect(find.byType(AppFilterSheetButton), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('app_filter_sheet')).first);
      final _ = await tester.pumpAndSettle();

      expect(
        tester.getSize(find.byType(BottomSheet)).height,
        lessThan(size.height * 0.9),
      );
      expect(find.text('Filters'), findsOneWidget);
      expect(find.text('Source'), findsOneWidget);

      final _ = await tester.tapAt(.new(size.width / 2, 0));
      final _ = await tester.pumpAndSettle();
    }
  });
}
