import 'package:auravibes_app/widgets/friendly_build_error_widget.dart';
import 'package:flutter/foundation.dart' show FlutterErrorDetails, kDebugMode;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('shows friendly text without Aura or localization ancestors', (
    tester,
  ) async {
    final details = FlutterErrorDetails(
      exception: StateError('debug-only diagnostic'),
      stack: .fromString('debug-only stack'),
    );

    await tester.pumpWidget(
      SizedBox(
        width: 400,
        height: 600,
        child: FriendlyBuildErrorWidget(details: details),
      ),
    );

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.text('Restarting the app should fix it.'), findsOneWidget);
    if (kDebugMode) {
      expect(find.textContaining('debug-only diagnostic'), findsOneWidget);
    } else {
      expect(find.textContaining('debug-only diagnostic'), findsNothing);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('renders a compact badge in a narrow layout', (tester) async {
    await tester.pumpWidget(
      SizedBox(
        width: 120,
        height: 120,
        child: FriendlyBuildErrorWidget(
          details: .new(exception: StateError('small slot')),
        ),
      ),
    );

    expect(find.byIcon(Icons.priority_high_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('long press copies exception and stack details', (tester) async {
    String? copiedText;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copiedText = (call.arguments as Map)['text'] as String?;
        }

        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    await tester.pumpWidget(
      SizedBox(
        width: 400,
        height: 600,
        child: FriendlyBuildErrorWidget(
          details: .new(
            exception: StateError('support diagnostic'),
            stack: .fromString('support stack'),
          ),
        ),
      ),
    );

    await tester.longPress(find.byType(FriendlyBuildErrorWidget));
    await tester.pump(const Duration(milliseconds: 300));

    expect(copiedText, contains('support diagnostic'));
    expect(copiedText, contains('support stack'));
    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });
}
