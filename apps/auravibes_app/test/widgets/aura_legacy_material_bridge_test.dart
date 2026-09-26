import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  testWidgets('provides compatibility to legacy package widgets', (
    tester,
  ) async {
    const bridgeKey = ValueKey('legacy-bridge');
    await tester.pumpWidget(
      MaterialApp(
        home: AuraThemeScope(
          theme: .light,
          child: const AuraLegacyMaterialBridge(
            child: Column(
              children: [
                AuraInput(placeholder: Text('Input')),
                TextField(),
              ],
            ),
            key: bridgeKey,
          ),
        ),
      ),
    );

    expect(find.byKey(bridgeKey), findsOneWidget);
    // ignore: deprecated_member_use - Verify legacy wrapper.
    expect(find.byType(MaterialUiCompatibilityBridge), findsOneWidget);
    expect(find.byType(AuraInput), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
