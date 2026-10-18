/// App shell's responsive layout policy.
abstract final class ResponsiveShellLayout {
  /// Logical width at which desktop layout begins.
  static const double desktopBreakpoint = 900;

  /// Logical width at which the expanded desktop sidebar is the default.
  static const double expandedSidebarBreakpoint = 1100;

  /// Whether [width] selects the desktop layout.
  static bool isDesktop(double width) => width >= desktopBreakpoint;

  /// Whether desktop layout defaults to compact navigation at [width].
  static bool isCompactDesktop(double width) =>
      isDesktop(width) && width < expandedSidebarBreakpoint;
}
