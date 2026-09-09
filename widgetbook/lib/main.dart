// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart' hide ThemeMode;
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';
import 'package:widgetbook_workspace/components.g.dart';

const _auraLocales = <Locale>[Locale('en'), Locale('es'), Locale('ar')];

void main() {
  final _ = WidgetsFlutterBinding.ensureInitialized();
  runWidgetbook(WidgetbookConfig.create());
}

abstract final class WidgetbookConfig {
  static Config create() {
    return Config(
      components: components,
      addons: [
        GridAddon(),
        TextScaleAddon(),
        SemanticsAddon(),
        TimeDilationAddon(),
        LocaleAddon(_auraLocales, StoryHelpers.auraLocalizationDelegates),
        AuraDirectionalityAddon(),
        ViewportAddon([
          Viewports.none,
          StoryHelpers.compactPhoneViewport,
          StoryHelpers.landscapePhoneViewport,
          StoryHelpers.tabletViewport,
          IosViewports.iPhone13,
          IosViewports.iPadAir4,
          AndroidViewports.samsungGalaxyNote20,
          MacosViewports.macbookPro,
          WindowsViewports.desktop,
          LinuxViewports.desktop,
        ]),
        ThemeAddon<ThemeData>(
          {'Aura Light': _createLightTheme(), 'Aura Dark': _createDarkTheme()},
          (context, theme, child) {
            return Theme(data: theme, child: child);
          },
        ),
        BuilderAddon(
          name: 'portal',
          builder: (context, child) =>
              Portal(child: AuraSnackBarHost(child: child)),
        ),
        BuilderAddon(
          name: 'SafeArea',
          builder: (ctx, child) => ColoredBox(
            color: ctx.auraColors.surface,
            child: SafeArea(child: child),
          ),
        ),
        AlignmentAddon(),
        ZoomAddon(),
      ],
      scenarioConfig: .new(
        definitions: [
          ScenarioDefinition(
            name: 'Aura Light',
            modes: [
              ThemeMode<ThemeData>(
                'Aura Light',
                _createLightTheme(),
                applyTheme,
              ),
            ],
            strategy: .perStory,
          ),
          ScenarioDefinition(
            name: 'Aura Dark',
            modes: [
              ThemeMode<ThemeData>('Aura Dark', _createDarkTheme(), applyTheme),
            ],
            strategy: .perStory,
          ),
        ],
      ),
    );
  }

  static Widget applyTheme(BuildContext _, ThemeData theme, Widget child) {
    return Theme(data: theme, child: child);
  }
}

ThemeData _createLightTheme() {
  return ThemeData(
    extensions: [AuraTheme.light],
    useMaterial3: true,
    colorScheme: _createColorScheme(.light, .light),
    textTheme: _createTextTheme(.light, ThemeData.light().textTheme),
  );
}

ThemeData _createDarkTheme() {
  return ThemeData(
    extensions: [AuraTheme.dark],
    useMaterial3: true,
    colorScheme: _createColorScheme(.dark, .dark),
    textTheme: _createTextTheme(.dark, ThemeData.dark().textTheme),
  );
}

ColorScheme _createColorScheme(AuraTheme auraTheme, Brightness brightness) {
  final colors = auraTheme.colors;

  return ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.primaryVariant,
    onPrimaryContainer: colors.onPrimary,
    primaryFixed: colors.primary,
    primaryFixedDim: colors.primaryVariant,
    onPrimaryFixed: colors.onPrimary,
    onPrimaryFixedVariant: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    secondaryContainer: colors.secondaryVariant,
    onSecondaryContainer: colors.onSecondary,
    secondaryFixed: colors.secondary,
    secondaryFixedDim: colors.secondaryVariant,
    onSecondaryFixed: colors.onSecondary,
    onSecondaryFixedVariant: colors.onSecondary,
    tertiary: colors.tertiary,
    onTertiary: colors.onTertiary,
    tertiaryContainer: colors.tertiaryVariant,
    onTertiaryContainer: colors.onTertiary,
    tertiaryFixed: colors.tertiary,
    tertiaryFixedDim: colors.tertiaryVariant,
    onTertiaryFixed: colors.onTertiary,
    onTertiaryFixedVariant: colors.onTertiary,
    error: colors.error,
    onError: colors.onError,
    errorContainer: colors.error,
    onErrorContainer: colors.onError,
    surface: colors.surface,
    onSurface: colors.onSurface,
    surfaceDim: colors.surface,
    surfaceBright: colors.surfaceVariant,
    surfaceContainerLowest: colors.surface,
    surfaceContainerLow: colors.surface,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceVariant,
    surfaceContainerHighest: colors.surfaceVariant,
    onSurfaceVariant: colors.onSurfaceVariant,
    outline: colors.outline,
    outlineVariant: colors.outlineVariant,
    shadow: colors.shadow,
    scrim: colors.scrim,
    inverseSurface: colors.onSurface,
    onInverseSurface: colors.surface,
    inversePrimary: colors.primaryVariant,
    surfaceTint: colors.primary,
  );
}

TextTheme _createTextTheme(AuraTheme auraTheme, TextTheme base) {
  return base.apply(fontFamily: auraTheme.typography.bodyFontFamily);
}
