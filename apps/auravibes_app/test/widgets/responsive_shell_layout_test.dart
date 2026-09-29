import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveShellLayout.isDesktop', () {
    test('selects mobile immediately below the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(959), isFalse);
    });

    test('selects desktop at the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(960), isTrue);
    });

    test('keeps mid-size widths in overlay mode', () {
      expect(ResponsiveShellLayout.isDesktop(600), isFalse);
    });

    test('keeps narrow widths in overlay mode', () {
      expect(ResponsiveShellLayout.isDesktop(599), isFalse);
    });

    test('selects desktop immediately above the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(961), isTrue);
    });
  });
}
