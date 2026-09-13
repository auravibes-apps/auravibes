import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('builds legacy package widgets below the bridge', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AuraLegacyMaterialBridge(child: GptMarkdown('Legacy content')),
      ),
    );

    expect(find.text('Legacy content'), findsOneWidget);
  });
}
