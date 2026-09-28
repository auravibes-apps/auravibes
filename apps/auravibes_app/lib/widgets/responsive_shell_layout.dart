/// App shell's responsive layout policy.
abstract final class ResponsiveShellLayout {
  /// Logical width at which desktop layout begins.
  static const double desktopBreakpoint = 600;

  /// Whether [width] selects the desktop layout.
  static bool isDesktop(double width) => width >= desktopBreakpoint;
}
