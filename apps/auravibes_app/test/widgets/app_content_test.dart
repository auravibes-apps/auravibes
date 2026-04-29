import 'package:auravibes_app/widgets/app_content.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders child widget', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: const Scaffold(
          body: AppContent(
            child: Text('child content'),
          ),
        ),
      ),
    );

    expect(find.text('child content'), findsOneWidget);
    expect(find.byType(AppContent), findsOneWidget);
  });

  testWidgets('constrains max width to DesignBreakpoints.sm', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [AuraTheme.light]),
        home: const Scaffold(
          body: AppContent(
            child: SizedBox.shrink(),
          ),
        ),
      ),
    );

    final constrainedBox = tester.widget<ConstrainedBox>(
      find.descendant(
        of: find.byType(AppContent),
        matching: find.byType(ConstrainedBox),
      ),
    );

    expect(
      constrainedBox.constraints.maxWidth,
      equals(DesignBreakpoints.sm),
    );
  });
}
