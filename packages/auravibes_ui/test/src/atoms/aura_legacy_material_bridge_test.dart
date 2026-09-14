import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('builds legacy package widgets below the bridge', (tester) async {
    final bridgeKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        home: AuraLegacyMaterialBridge(
          child: const GptMarkdown('Legacy content'),
          key: bridgeKey,
        ),
      ),
    );

    expect(find.byKey(bridgeKey), findsOneWidget);
    expect(find.text('Legacy content'), findsOneWidget);
  });
}
