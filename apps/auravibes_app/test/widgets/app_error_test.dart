import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('renders error message', (tester) async {
    const error = 'test error message';

    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AppErrorWidget(
            error: error,
            stackTrace: StackTrace.empty,
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Error loading models: $error'), findsNothing);
    expect(find.byIcon(Icons.error_outline), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
    expect(find.byType(AuraText), findsNWidgets(2));
  });

  testWidgets('renders different error types', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: const Scaffold(
          body: AppErrorWidget(
            error: 42,
            stackTrace: StackTrace.empty,
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Error loading models: 42'), findsNothing);
    expect(
      find.byWidgetPredicate((widget) => widget is AppErrorWidget),
      findsOneWidget,
    );
  });

  testWidgets('renders optional action', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AppErrorWidget(
            error: StateError('failed'),
            stackTrace: StackTrace.empty,
            action: const Text('Retry'),
          ),
        ),
        theme: ThemeData(extensions: [AuraTheme.light]),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
  });
}
