import 'package:auravibes_app/widgets/app_visibility_base.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

void main() {
  testWidgets('shows child when visible is true', (tester) async {
    final visibleProvider = Provider<bool>((ref) => true);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppVisibilityBase(
              visible: visibleProvider,
              child: const Text('visible content'),
            ),
          ),
        ),
      ),
    );

    expect(find.byType(AppVisibilityBase), findsOneWidget);
    expect(find.byType(Visibility), findsOneWidget);
    final visibility = tester.widget<Visibility>(find.byType(Visibility));
    expect(visibility.visible, isTrue);
  });

  testWidgets('hides child when visible is false', (tester) async {
    final visibleProvider = Provider<bool>((ref) => false);

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: AppVisibilityBase(
              visible: visibleProvider,
              child: const Text('visible content'),
            ),
          ),
        ),
      ),
    );

    final visibility = tester.widget<Visibility>(find.byType(Visibility));
    expect(visibility.visible, isFalse);
  });
}
