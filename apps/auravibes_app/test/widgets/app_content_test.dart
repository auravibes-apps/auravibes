import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders child widget', (tester) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(body: AppContent(child: Text('child content'))),
          theme: .new(),
        ),
      ),
    );

    expect(find.text('child content'), findsOneWidget);
    expect(find.byType(AppContent), findsOneWidget);
  });

  testWidgets('constrains max width to DesignBreakpoints.sm', (tester) async {
    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(body: AppContent(child: SizedBox.shrink())),
          theme: .new(),
        ),
      ),
    );

    final constrainedBox = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(AppContent),
        matching: find.byType(ConstrainedBox),
      ),
    );

    expect(constrainedBox.constraints.maxWidth, equals(DesignBreakpoints.sm));
  });
}
