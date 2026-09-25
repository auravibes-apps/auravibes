import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('responsiveShellLayoutForWidth', () {
    test('selects mobile immediately below the breakpoint', () {
      expect(responsiveShellLayoutForWidth(599), ResponsiveShellLayout.mobile);
    });

    test('selects desktop at the breakpoint', () {
      expect(responsiveShellLayoutForWidth(600), ResponsiveShellLayout.desktop);
    });

    test('selects desktop immediately above the breakpoint', () {
      expect(responsiveShellLayoutForWidth(601), ResponsiveShellLayout.desktop);
    });
  });
}
