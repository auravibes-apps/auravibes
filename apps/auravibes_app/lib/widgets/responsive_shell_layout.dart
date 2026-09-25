/// Responsive layout variants supported by the app shell.
enum ResponsiveShellLayout { mobile, desktop }

/// Width at which the app shell switches to desktop layout.
const responsiveShellDesktopBreakpoint = 600.0;

/// Selects an app-shell layout for a logical viewport [width].
ResponsiveShellLayout responsiveShellLayoutForWidth(double width) =>
    width < responsiveShellDesktopBreakpoint
    ? ResponsiveShellLayout.mobile
    : ResponsiveShellLayout.desktop;
