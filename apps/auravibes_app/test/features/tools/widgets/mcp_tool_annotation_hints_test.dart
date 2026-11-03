import 'package:auravibes_app/features/tools/widgets/mcp_tool_annotation_hints.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/test_app.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();
  });

  testWidgets('shows true and false hints as localized accessible labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestableApp(
        child: McpToolAnnotationHints(
          annotations: {'readOnlyHint': false, 'destructiveHint': true},
        ),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    const mayModify = 'Service hint: may modify information';
    const mayChange = 'Service hint: may change or remove information';
    expect(find.text(mayModify), findsOneWidget);
    expect(find.text(mayChange), findsOneWidget);
    expect(find.bySemanticsLabel(mayModify), findsOneWidget);
    expect(find.bySemanticsLabel(mayChange), findsOneWidget);
  });

  testWidgets('uses the selected locale for informational labels', (
    tester,
  ) async {
    await tester.pumpWidget(
      const TestableApp(
        startLocale: Locale('es'),
        child: McpToolAnnotationHints(annotations: {'readOnlyHint': false}),
      ),
    );
    await tester.pumpAndSettle();
    final semantics = tester.ensureSemantics();
    addTearDown(semantics.dispose);

    const label = 'Indicación del servicio: podría modificar información';
    expect(find.text(label), findsOneWidget);
    expect(find.bySemanticsLabel(label), findsOneWidget);
  });
}
