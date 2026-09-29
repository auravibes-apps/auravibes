import 'package:auravibes_app/features/settings/widgets/app_version_indicator.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  for (final (:buildNumber, :label) in [
    (buildNumber: '45', label: 'AuraVibes 1.2.3 (45)'),
    (buildNumber: '', label: 'AuraVibes 1.2.3'),
  ]) {
    testWidgets('shows app version with build number "$buildNumber"', (
      tester,
    ) async {
      PackageInfo.setMockInitialValues(
        appName: 'AuraVibes',
        packageName: 'me.auravibes.app',
        version: '1.2.3',
        buildNumber: buildNumber,
        buildSignature: '',
      );

      await tester.pumpWidget(
        AuraThemeScope(
          theme: .light,
          child: const MaterialApp(home: AppVersionIndicator()),
        ),
      );
      expect(find.text(label), findsNothing);
      await tester.pump();

      expect(find.text(label), findsOneWidget);
    });
  }
}
