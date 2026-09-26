import 'package:auravibes_app/widgets/app_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('renders error message', (tester) async {
    const error = 'test error message';

    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            body: AppErrorWidget(error: error, stackTrace: .empty),
          ),
          theme: .new(),
        ),
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
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: const Scaffold(
            body: AppErrorWidget(error: 42, stackTrace: .empty),
          ),
          theme: .new(),
        ),
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
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(
              error: StateError('failed'),
              stackTrace: .empty,
              action: const Text('Retry'),
            ),
          ),
          theme: .new(),
        ),
      ),
    );

    expect(find.text('Retry'), findsOneWidget);
  });

  testWidgets('logs displayed error with its stack trace', (tester) async {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen(records.add);
    final error = StateError('failed');
    final stackTrace = StackTrace.current;

    await tester.pumpWidget(
      AuraThemeScope(
        theme: .light,
        child: MaterialApp(
          home: Scaffold(
            body: AppErrorWidget(error: error, stackTrace: stackTrace),
          ),
          theme: .new(),
        ),
      ),
    );

    subscription.cancel();

    expect(
      records.where((record) => record.loggerName == 'app_error_widget'),
      contains(
        isA<LogRecord>()
            .having((record) => record.level, 'level', Level.SEVERE)
            .having((record) => record.error, 'error', error)
            .having((record) => record.stackTrace, 'stackTrace', stackTrace),
      ),
    );
  });
}
