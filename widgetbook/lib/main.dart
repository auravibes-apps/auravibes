import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

import 'main.directories.g.dart';

void main() {
  runApp(const WidgetbookApp());
}

@widgetbook.App()
class WidgetbookApp extends StatelessWidget {
  const WidgetbookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Widgetbook.material(
      // themeMode: .light,
      // Use the generated directories variable
      directories: directories,
      addons: [
        InspectorAddon(enabled: true),
        TextScaleAddon(),
        SemanticsAddon(),
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyNote20,
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          LinuxViewports.desktop,
        ]),
        ThemeAddon(
          themeBuilder: (context, theme, child) =>
              Theme(data: theme, child: child),
          themes: [
            WidgetbookTheme(name: 'Aura Light', data: _createLightTheme()),
            WidgetbookTheme(name: 'Aura Dark', data: _createDarkTheme()),
          ],
        ),
        BuilderAddon(
          name: 'SafeArea',
          builder: (ctx, child) => ColoredBox(
            color: ctx.auraColors.surface,

            child: SafeArea(child: child),
          ),
        ),
        AlignmentAddon(),
        // BuilderAddon(name: 'Builder', builder: (context, child) => child),
      ],
    );
  }

  ThemeData _createLightTheme() {
    final auraColors = AuraTheme.light.colors;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: auraColors.primary,
        onPrimary: auraColors.onPrimary,
        secondary: auraColors.secondary,
        onSecondary: auraColors.onSecondary,
        surface: auraColors.surface,
        onSurface: auraColors.onSurface,
        error: auraColors.error,
        onError: auraColors.onError,
        outline: auraColors.outline,
      ),
      textTheme: GoogleFonts.interTextTheme(),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(
            fontWeight: DesignTypography.fontWeightMedium,
          ),
        ),
      ),
      extensions: [AuraTheme.light],
    );
  }

  ThemeData _createDarkTheme() {
    final auraColors = AuraTheme.dark.colors;
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: auraColors.primary,
        onPrimary: auraColors.onPrimary,
        secondary: auraColors.secondary,
        onSecondary: auraColors.onSecondary,
        surface: auraColors.surface,
        onSurface: auraColors.onSurface,
        error: auraColors.error,
        onError: auraColors.onError,
        outline: auraColors.outline,
      ),
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          textStyle: GoogleFonts.inter(
            fontWeight: DesignTypography.fontWeightMedium,
          ),
        ),
      ),
      extensions: [AuraTheme.dark],
    );
  }
}
