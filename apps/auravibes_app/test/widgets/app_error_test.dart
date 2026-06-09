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

    expect(find.text('Error loading models: $error'), findsOneWidget);
    expect(find.byType(AppErrorWidget<String>), findsOneWidget);
    expect(find.byType(AuraText), findsOneWidget);
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

    expect(find.text('Error loading models: 42'), findsOneWidget);
  });
}
