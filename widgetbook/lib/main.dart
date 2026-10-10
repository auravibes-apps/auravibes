// Required: Existing test and UI helpers keep compact return flow.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:material_ui/material_ui.dart' hide ThemeMode;
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';
import 'package:widgetbook_workspace/components.g.dart';

const _auraLocales = <Locale>[Locale('en'), Locale('es'), Locale('ar')];
const _defaultHue = 300;
const _hueSteps = 360;

void main() {
  final _ = WidgetsFlutterBinding.ensureInitialized();
  runWidgetbook(WidgetbookConfig.create());
}

abstract final class WidgetbookConfig {
  static Config create() => Config(
    components: components,
    appBuilder: applyApp,
    addons: _createAddons(),
    scenarioConfig: _createScenarioConfig(),
  );

  static Widget applyApp(BuildContext _, Widget child) => MaterialApp(
    home: child,
    localizationsDelegates: const [
      ...GlobalMaterialLocalizations.delegates,
      sdk_localizations.GlobalMaterialLocalizations.delegate,
    ],
    supportedLocales: _auraLocales,
    debugShowCheckedModeBanner: false,
  );

  static Widget applyTheme(
    ThemeData theme,
    Widget child, {
    int hue = _defaultHue,
  }) => _applyAuraTheme(theme, _createAuraTheme(theme.brightness, hue), child);

  static Widget _applyAuraTheme(
    ThemeData theme,
    AuraTheme auraTheme,
    Widget child,
  ) => Theme(
    data: _AuraThemeSeed.applyTo(theme, auraTheme),
    child: AuraSdkMaterialSurface(
      // ignore: deprecated_member_use - Widgetbook previews legacy dependencies.
      child: MaterialUiCompatibilityBridge(child: Material(child: child)),
    ),
  );

  // Hue addon builds the computed theme once, inside the selected brightness.
  static Widget _applyBrightness(
    BuildContext _,
    ThemeData theme,
    Widget child,
  ) => Theme(data: theme, child: child);

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

    return ThemeAddon<ThemeData>(themes, _applyBrightness);
  }

  static Addon _createPortalAddon() => BuilderAddon(
    name: 'portal',
    builder: (context, child) => Portal(child: AuraSnackBarHost(child: child)),
  );

  static Addon _createSafeAreaAddon() => BuilderAddon(
    name: 'SafeArea',
    builder: (ctx, child) => ColoredBox(
      color: ctx.auraColors.background,
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
  AuraHueAddon(),
  _GlobalBorderRadiusAddon(),
  WidgetbookConfig._createPortalAddon(),
  WidgetbookConfig._createSafeAreaAddon(),
  AlignmentAddon(),
  ZoomAddon(),
];

/// Changes the preview's brand hue while retaining its selected brightness.
class AuraHueAddon() extends Addon<int> with SingleFieldOnly {
  this : super(name: 'Hue', initialValue: _defaultHue);

  @override
  Field<int> get field => IntSliderField(
    name: 'degrees',
    initialValue: initialValue,
    min: 0,
    max: _hueSteps,
    divisions: _hueSteps,
  );

  @override
  Widget apply(BuildContext context, Widget child, int setting) =>
      WidgetbookConfig.applyTheme(Theme.of(context), child, hue: setting);
}

class _GlobalBorderRadiusAddon()
    extends Addon<AuraBorderRadius>
    with SingleFieldOnly {
  this : super(name: 'Global border radius level', initialValue: .lg);

  @override
  Field<AuraBorderRadius> get field => ObjectDropdownField<AuraBorderRadius>(
    name: 'level',
    values: AuraBorderRadius.values,
    initialValue: initialValue,
    labelBuilder: (value) => value.name,
  );

  @override
  Widget apply(BuildContext context, Widget child, AuraBorderRadius setting) {
    return _AnimatedAuraThemeScope(
      baseTheme:
          Theme.of(context).extension<_AuraThemeSeed>()?.theme ??
          _createAuraTheme(Theme.of(context).brightness, _defaultHue),
      level: setting,
      child: child,
    );
  }
}

// Shares the hue-derived base theme without adding another inherited scope.
class _AuraThemeSeed extends ThemeExtension<_AuraThemeSeed> {
  const new({required this.theme});

  final AuraTheme theme;

  static ThemeData applyTo(ThemeData theme, AuraTheme auraTheme) =>
      theme.copyWith(
        colorScheme: _createColorScheme(auraTheme, theme.brightness),
        scaffoldBackgroundColor: auraTheme.colors.background,
        extensions: [
          ...theme.extensions.values.where(
            (extension) => extension is! _AuraThemeSeed,
          ),
          _AuraThemeSeed(theme: auraTheme),
        ],
      );

  @override
  _AuraThemeSeed copyWith() => this;

  @override
  _AuraThemeSeed lerp(covariant _AuraThemeSeed? other, double t) =>
      other == null ? this : _AuraThemeSeed(theme: theme.lerp(other.theme, t));
}

class _AnimatedAuraThemeScope extends StatefulWidget {
  const new({
    required this.baseTheme,
    required this.level,
    required this.child,
  });

  final AuraTheme baseTheme;
  final AuraBorderRadius level;
  final Widget child;

  @override
  State<_AnimatedAuraThemeScope> createState() =>
      _AnimatedAuraThemeScopeState();
}

class _AnimatedAuraThemeScopeState extends State<_AnimatedAuraThemeScope> {
  AuraTheme _targetTheme = .light;

  @override
  void initState() {
    super.initState();
    _targetTheme = _resolveAuraTheme(widget);
  }

  @override
  void didUpdateWidget(_AnimatedAuraThemeScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.baseTheme, oldWidget.baseTheme) ||
        widget.level != oldWidget.level) {
      _targetTheme = _resolveAuraTheme(widget);
    }
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<AuraTheme>(
    tween: _AuraThemeTween(end: _targetTheme),
    duration: _targetTheme.animation.normal,
    curve: Curves.easeInOut,
    builder: _buildThemeScope,
    child: widget.child,
  );

  Widget _buildThemeScope(BuildContext _, AuraTheme theme, Widget? child) =>
      AuraThemeScope(theme: theme, child: child ?? widget.child);
}

AuraTheme _resolveAuraTheme(_AnimatedAuraThemeScope widget) =>
    widget.baseTheme.copyWith(globalBorderRadiusLevel: widget.level);

AuraTheme _createAuraTheme(Brightness brightness, int hue) {
  final isLight = brightness == Brightness.light;

  return (isLight ? AuraTheme.light : AuraTheme.dark).copyWith(
    colors: AuraComputedColorScheme(
      primaryHue: hue.toDouble(),
      brightness: isLight ? .light : .dark,
    ),
  );
}

class _AuraThemeTween extends Tween<AuraTheme> {
  new({required AuraTheme end}) : super(begin: end, end: end);

  @override
  AuraTheme lerp(double t) => (begin ?? end ?? AuraTheme.light).lerp(
    end ?? begin ?? AuraTheme.light,
    t,
  );
}

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
      WidgetbookConfig._applyBrightness,
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
      WidgetbookConfig._applyBrightness,
    ),
  ],
  strategy: .perStory,
);

ThemeData _createLightTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: _createColorScheme(.light, .light),
    textTheme: _createTextTheme(.light, ThemeData.light().textTheme),
  );
}

ThemeData _createDarkTheme() {
  return ThemeData(
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
    onErrorContainer: colors.onError,
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
