import 'package:auravibes_ui/src/atoms/aura_loading_circle.dart';
import 'package:auravibes_ui/src/atoms/aura_message_status.dart';
import 'package:auravibes_ui/src/atoms/aura_typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('indicators stop and resume when reduced motion changes', (
    tester,
  ) async {
    Widget frame({required bool reduced}) => MaterialApp(
      home: MediaQuery(
        data: .new(disableAnimations: reduced),
        child: const Column(
          children: [
            AuraTypingIndicator(key: ValueKey('typing'), showContainer: false),
            AuraLoadingCircle(tint: .primary, key: ValueKey('loading')),
            AuraMessageStatus(status: .sending, key: ValueKey('status')),
          ],
        ),
      ),
    );

    Finder within(String key, Finder matching) => find.descendant(
      of: find.byKey(ValueKey<String>(key)),
      matching: matching,
    );
    List<double> typingOpacity() => tester
        .widgetList<Opacity>(within('typing', find.byType(Opacity)))
        .map((widget) => widget.opacity)
        .toList();
    List<double> loadingOpacity() => tester
        .widgetList<FadeTransition>(
          within('loading', find.byType(FadeTransition)),
        )
        .map((widget) => widget.opacity.value)
        .toList();

    await tester.pumpWidget(frame(reduced: true));
    final typing = typingOpacity();
    final loading = loadingOpacity();
    await tester.pump(const Duration(milliseconds: 300));
    expect(typingOpacity(), typing);
    expect(loadingOpacity(), loading);
    expect(within('status', find.byType(AnimatedBuilder)), findsNothing);
    expect(within('status', find.byIcon(Icons.access_time)), findsOneWidget);

    await tester.pumpWidget(frame(reduced: false));
    await tester.pump(const Duration(milliseconds: 300));
    expect(typingOpacity(), isNot(typing));
    expect(loadingOpacity(), isNot(loading));
    expect(within('status', find.byType(AnimatedBuilder)), findsOneWidget);
  });
}
