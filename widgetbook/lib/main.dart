// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
// ignore_for_file: member-ordering
// Required: Existing declaration order groups related UI and model members.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/main.directories.g.dart';

void main() {
  runApp(const ProviderScope(child: WidgetbookApp()));
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
        SemanticsAddon(), // ignore: experimental_member_use
        ViewportAddon([
          Viewports.none,
          IosViewports.iPhone13,
          AndroidViewports.samsungGalaxyNote20,
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          LinuxViewports.desktop,
        ]),
        ThemeAddon(
          themes: [
            WidgetbookTheme(name: 'Aura Light', data: _createLightTheme()),
            WidgetbookTheme(name: 'Aura Dark', data: _createDarkTheme()),
          ],
          themeBuilder: (context, theme, child) =>
              Theme(data: theme, child: child),
        ),
        BuilderAddon(
          name: 'portal',
          builder: (context, child) {
            return Portal(child: child);
          },
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
      extensions: [AuraTheme.light],
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.light,
        primary: auraColors.primary,
        onPrimary: auraColors.onPrimary,
        secondary: auraColors.secondary,
        onSecondary: auraColors.onSecondary,
        error: auraColors.error,
        onError: auraColors.onError,
        surface: auraColors.surface,
        onSurface: auraColors.onSurface,
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
    );
  }

  ThemeData _createDarkTheme() {
    final auraColors = AuraTheme.dark.colors;
    return ThemeData(
      extensions: [AuraTheme.dark],
      useMaterial3: true,
      colorScheme: ColorScheme(
        brightness: Brightness.dark,
        primary: auraColors.primary,
        onPrimary: auraColors.onPrimary,
        secondary: auraColors.secondary,
        onSecondary: auraColors.onSecondary,
        error: auraColors.error,
        onError: auraColors.onError,
        surface: auraColors.surface,
        onSurface: auraColors.onSurface,
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
    );
  }
}
