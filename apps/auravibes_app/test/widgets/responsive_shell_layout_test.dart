import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveShellLayout.isDesktop', () {
    test('selects mobile immediately below the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(599), isFalse);
    });

    test('selects desktop at the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(600), isTrue);
    });

    test('selects desktop immediately above the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(601), isTrue);
    });
  });
}
