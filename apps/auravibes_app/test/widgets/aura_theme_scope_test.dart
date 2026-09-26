import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';

void main() {
  testWidgets('test app scopes Aura theme independently of host theme', (
    tester,
  ) async {
    AuraTheme? observedTheme;
    await tester.pumpWidget(
      TestableApp(
        child: Builder(
          builder: (context) {
            observedTheme = context.auraTheme;

            return const SizedBox.shrink();
          },
        ),
      ),
    );
    final _ = await tester.pumpAndSettle();

    expect(observedTheme, same(AuraTheme.light));
  });
}
