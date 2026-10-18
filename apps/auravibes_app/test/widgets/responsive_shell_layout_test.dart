import 'package:auravibes_app/widgets/responsive_shell_layout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResponsiveShellLayout.isDesktop', () {
    test('selects mobile immediately below the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(899), isFalse);
    });

    test('selects desktop at the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(900), isTrue);
    });

    test('keeps mid-size widths in overlay mode', () {
      expect(ResponsiveShellLayout.isDesktop(600), isFalse);
    });

    test('keeps narrow widths in overlay mode', () {
      expect(ResponsiveShellLayout.isDesktop(599), isFalse);
    });

    test('selects desktop immediately above the breakpoint', () {
      expect(ResponsiveShellLayout.isDesktop(901), isTrue);
    });
  });

  group('ResponsiveShellLayout.isCompactDesktop', () {
    test('defaults to overlay navigation below desktop breakpoint', () {
      expect(ResponsiveShellLayout.isCompactDesktop(899), isFalse);
    });

    test('defaults to compact navigation at desktop breakpoint', () {
      expect(ResponsiveShellLayout.isCompactDesktop(900), isTrue);
    });

    test('keeps compact navigation through the Duo inner width', () {
      expect(ResponsiveShellLayout.isCompactDesktop(951), isTrue);
    });

    test('defaults to expanded navigation at expanded breakpoint', () {
      expect(ResponsiveShellLayout.isCompactDesktop(1100), isFalse);
    });
  });
}
