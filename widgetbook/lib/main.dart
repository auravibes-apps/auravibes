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
  static Config create() => Config(
    components: components,
    addons: _createAddons(),
    scenarioConfig: _createScenarioConfig(),
  );

  static Widget applyTheme(BuildContext _, ThemeData theme, Widget child) =>
      Theme(data: theme, child: child);

  static Addon _createViewportAddon() => ViewportAddon([
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
  ]);

  static Addon _createThemeAddon() {
    final themes = <String, ThemeData>{
      'Aura Light': _createLightTheme(),
      'Aura Dark': _createDarkTheme(),
    };

    return ThemeAddon<ThemeData>(themes, applyTheme);
  }

  static Addon _createPortalAddon() => BuilderAddon(
    name: 'portal',
    builder: (context, child) => Portal(child: AuraSnackBarHost(child: child)),
  );

  static Addon _createSafeAreaAddon() => BuilderAddon(
    name: 'SafeArea',
    builder: (ctx, child) => ColoredBox(
      color: ctx.auraColors.surface,
      child: SafeArea(child: child),
    ),
  );

  static ScenarioConfig _createScenarioConfig() =>
      .new(definitions: [_createLightScenario(), _createDarkScenario()]);
}

List<Addon> _createAddons() => [
  ..._createBaseAddons(),
  WidgetbookConfig._createViewportAddon(),
  WidgetbookConfig._createThemeAddon(),
  WidgetbookConfig._createPortalAddon(),
  WidgetbookConfig._createSafeAreaAddon(),
  AlignmentAddon(),
  ZoomAddon(),
];

List<Addon> _createBaseAddons() => [
  GridAddon(),
  TextScaleAddon(),
  SemanticsAddon(),
  TimeDilationAddon(),
  LocaleAddon(_auraLocales, StoryHelpers.auraLocalizationDelegates),
  AuraDirectionalityAddon(),
];

ScenarioDefinition _createLightScenario() => ScenarioDefinition(
  name: 'Aura Light',
  modes: [
    ThemeMode<ThemeData>(
      'Aura Light',
      _createLightTheme(),
      WidgetbookConfig.applyTheme,
    ),
  ],
  strategy: .perStory,
);

ScenarioDefinition _createDarkScenario() => ScenarioDefinition(
  name: 'Aura Dark',
  modes: [
    ThemeMode<ThemeData>(
      'Aura Dark',
      _createDarkTheme(),
      WidgetbookConfig.applyTheme,
    ),
  ],
  strategy: .perStory,
);

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
  final scheme = brightness == Brightness.light
      ? const ColorScheme.light()
      : const ColorScheme.dark();

  return _withPrimaryColors(
    _withSecondaryColors(
      _withTertiaryColors(_withSurfaceColors(scheme, auraTheme), auraTheme),
      auraTheme,
    ),
    auraTheme,
  );
}

ColorScheme _withPrimaryColors(ColorScheme scheme, AuraTheme auraTheme) {
  return _withPrimaryFixedColors(
    _withPrimaryBaseColors(scheme, auraTheme),
    auraTheme,
  );
}

ColorScheme _withPrimaryBaseColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.primaryVariant,
    onPrimaryContainer: colors.onPrimary,
    primaryFixed: colors.primary,
    primaryFixedDim: colors.primaryVariant,
    onPrimaryFixed: colors.onPrimary,
    onPrimaryFixedVariant: colors.onPrimary,
  );
}

ColorScheme _withPrimaryFixedColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    inversePrimary: colors.primaryVariant,
    surfaceTint: colors.primary,
  );
}

ColorScheme _withSecondaryColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    secondaryContainer: colors.secondaryVariant,
    onSecondaryContainer: colors.onSecondary,
    secondaryFixed: colors.secondary,
    secondaryFixedDim: colors.secondaryVariant,
    onSecondaryFixed: colors.onSecondary,
    onSecondaryFixedVariant: colors.onSecondary,
  );
}

ColorScheme _withTertiaryColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    tertiary: colors.tertiary,
    onTertiary: colors.onTertiary,
    tertiaryContainer: colors.tertiaryVariant,
    onTertiaryContainer: colors.onTertiary,
    tertiaryFixed: colors.tertiary,
    tertiaryFixedDim: colors.tertiaryVariant,
    onTertiaryFixed: colors.onTertiary,
    onTertiaryFixedVariant: colors.onTertiary,
  );
}

ColorScheme _withSurfaceColors(ColorScheme scheme, AuraTheme auraTheme) {
  return _withInverseColors(
    _withSurfacePaletteColors(_withErrorColors(scheme, auraTheme), auraTheme),
    auraTheme,
  );
}

ColorScheme _withErrorColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    error: colors.error,
    onError: colors.onError,
    errorContainer: colors.error,
    onErrorContainer: colors.error,
  );
}

ColorScheme _withSurfacePaletteColors(ColorScheme scheme, AuraTheme auraTheme) {
  return _withSurfaceOutlineColors(
    _withSurfaceContainers(
      _withSurfaceBaseColors(scheme, auraTheme),
      auraTheme,
    ),
    auraTheme,
  );
}

ColorScheme _withSurfaceBaseColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    surface: colors.surface,
    onSurface: colors.onSurface,
    surfaceDim: colors.surface,
    surfaceBright: colors.surfaceVariant,
  );
}

ColorScheme _withSurfaceContainers(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    surfaceContainerLowest: colors.surface,
    surfaceContainerLow: colors.surface,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceVariant,
    surfaceContainerHighest: colors.surfaceVariant,
  );
}

ColorScheme _withSurfaceOutlineColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    onSurfaceVariant: colors.onSurfaceVariant,
    outline: colors.outline,
    outlineVariant: colors.outlineVariant,
    shadow: colors.shadow,
    scrim: colors.scrim,
  );
}

ColorScheme _withInverseColors(ColorScheme scheme, AuraTheme auraTheme) {
  final colors = auraTheme.colors;

  return scheme.copyWith(
    inverseSurface: colors.onSurface,
    onInverseSurface: colors.surface,
  );
}

TextTheme _createTextTheme(AuraTheme auraTheme, TextTheme base) {
  return base.apply(fontFamily: auraTheme.typography.bodyFontFamily);
}
