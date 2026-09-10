import 'dart:async';

import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main/main_locale.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/app_logging.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlayStyle, appFlavor;
import 'package:flutter_driver/driver_extension.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  _configureFlavor();
  _ensureFlutterBinding();
  _configureLogging();
  await MainLocale.ensureInitialized();

  _configureSystemUi();
  final container = ProviderContainer();

  _runApp(container);
  _scheduleModelSync(container);
}

void _configureFlavor() =>
    AppFlavorConfig.instance.setAppFlavor(AppFlavorResolver.resolve(appFlavor));

void _configureLogging() => AppLogging.configure(
  enabled: AppFlavorConfig.instance.appFlavor != Flavor.prod,
);

void _ensureFlutterBinding() {
  // Ponytail: debug-only bridge; enable only for MCP driver screenshots.
  if (kDebugMode && const bool.fromEnvironment('ENABLE_FLUTTER_DRIVER')) {
    final _ = enableFlutterDriverExtension();

    return;
  }

  final _ = WidgetsFlutterBinding.ensureInitialized();
}

void _configureSystemUi() {
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
}

void _runApp(ProviderContainer container) {
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainLocale(child: MyApp()),
    ),
  );
}

void _scheduleModelSync(ProviderContainer container) {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(container.read(modelSyncServiceProvider).performFullSync());
  });
}

class AppFlavorResolver._() {
  static Flavor resolve(String? flavorName) {
    if (flavorName == null) {
      throw StateError('appFlavor is not initialized');
    }

    return Flavor.values.byName(flavorName);
  }
}

class const MyApp({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef _) {
    return const _AppThemeView();
  }
}

class const _AppThemeView() extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) {
    return _MaterialAppShell(themeMode: _themeMode(ref), hue: _accentHue(ref));
  }
}

ThemeMode _themeMode(WidgetRef ref) {
  return ref.watch(themeProvider).asData?.value.themeMode ?? ThemeMode.system;
}

double _accentHue(WidgetRef ref) {
  return ref.watch(accentHueProvider).asData?.value ?? AccentHue.defaultValue;
}

class const _MaterialAppShell({
  required final ThemeMode themeMode,
  required final double hue,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext _, WidgetRef ref) {
    final routerConfig = ref.watch(routerProvider);

    return _MaterialAppRoot(
      routerConfig: routerConfig,
      lightTheme: _auraThemeData(hue, .light),
      darkTheme: _auraThemeData(hue, .dark),
      themeMode: themeMode,
    );
  }
}

ThemeData _auraThemeData(double hue, Brightness brightness) {
  final baseTheme = brightness == Brightness.light
      ? AuraTheme.light
      : AuraTheme.dark;
  final auraTheme = baseTheme.copyWith(
    colors: AuraComputedColorScheme(
      primaryHue: hue,
      brightness: brightness == Brightness.light ? .light : .dark,
    ),
  );

  return _auraMaterialTheme(auraTheme, brightness);
}

class const _MaterialAppRoot({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Portal(
      child: _MaterialAppRouter(
        routerConfig: routerConfig,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
      ),
    );
  }
}

class const _MaterialAppRouter({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MaterialAppRouterView(
      routerConfig: routerConfig,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
    );
  }
}

class const _MaterialAppRouterView({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = _appLocalization(context);

    return _AuraMaterialApp(
      routerConfig: routerConfig,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      locale: localization.locale,
      delegates: localization.delegates,
      locales: localization.locales,
    );
  }
}

class _AuraMaterialApp extends MaterialApp {
  new({
    required GoRouter routerConfig,
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required ThemeMode themeMode,
    required Locale locale,
    required Iterable<LocalizationsDelegate<dynamic>> delegates,
    required Iterable<Locale> locales,
  }) : super.router(
         routerConfig: routerConfig,
         builder: _snackBarBuilder,
         title: AppFlavorConfig.instance.title,
         theme: lightTheme,
         darkTheme: darkTheme,
         themeMode: themeMode,
         locale: locale,
         localizationsDelegates: delegates,
         supportedLocales: locales,
         debugShowCheckedModeBanner: _showDebugBanner,
       );
}

({
  Locale locale,
  Iterable<LocalizationsDelegate<dynamic>> delegates,
  Iterable<Locale> locales,
})
_appLocalization(BuildContext context) {
  return (
    locale: context.locale,
    delegates: context.localizationDelegates,
    locales: context.supportedLocales,
  );
}

Widget Function(BuildContext, Widget?) get _snackBarBuilder {
  return (_, child) => _AuraSnackBarHost(child: child);
}

bool get _showDebugBanner => AppFlavorConfig.instance.appFlavor != Flavor.prod;

class const _AuraSnackBarHost({required final Widget? child})
    extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return AuraSnackBarHost(
      child: AuraText(child: child ?? const SizedBox.shrink()),
    );
  }
}

ThemeData _auraMaterialTheme(AuraTheme auraTheme, Brightness brightness) {
  final parts = _auraThemeParts(auraTheme, brightness);
  final baseTheme = _auraBaseMaterialTheme(parts);

  return _auraFeedbackTheme(_auraControlTheme(baseTheme, parts), parts);
}

typedef _AuraThemeParts = ({
  AuraTheme auraTheme,
  Brightness brightness,
  AuraColorScheme colors,
  TextTheme textTheme,
});

_AuraThemeParts _auraThemeParts(AuraTheme auraTheme, Brightness brightness) => (
  auraTheme: auraTheme,
  brightness: brightness,
  colors: auraTheme.colors,
  textTheme: _auraTextTheme(auraTheme, brightness),
);

ThemeData _auraControlTheme(ThemeData baseTheme, _AuraThemeParts parts) {
  return baseTheme.copyWith(
    chipTheme: _auraChipTheme(parts),
    dialogTheme: _auraDialogTheme(
      parts.colors,
      parts.auraTheme,
      parts.textTheme,
    ),
    iconButtonTheme: _auraIconButtonTheme(parts.colors),
  );
}

ThemeData _auraFeedbackTheme(ThemeData baseTheme, _AuraThemeParts parts) {
  return baseTheme.copyWith(
    progressIndicatorTheme: _auraProgressIndicatorTheme(parts.colors),
    snackBarTheme: _auraSnackBarTheme(
      parts.colors,
      parts.auraTheme,
      parts.textTheme,
    ),
  );
}

ThemeData _auraBaseMaterialTheme(_AuraThemeParts parts) {
  return _buildBaseTheme(parts);
}

ThemeData _buildBaseTheme(_AuraThemeParts parts) =>
    _buildBaseThemeDetails(_buildBaseThemeCore(parts), parts);

ThemeData _buildBaseThemeCore(_AuraThemeParts parts) => ThemeData(
  extensions: [parts.auraTheme],
  useMaterial3: true,
  colorScheme: _auraColorScheme(parts.colors, parts.brightness),
  brightness: parts.brightness,
  fontFamily: parts.auraTheme.typography.bodyFontFamily,
);

ThemeData _buildBaseThemeDetails(ThemeData theme, _AuraThemeParts parts) =>
    theme.copyWith(
      scaffoldBackgroundColor: parts.colors.background,
      iconTheme: .new(color: parts.colors.onSurfaceVariant),
      primaryTextTheme: parts.textTheme,
      textTheme: parts.textTheme,
    );

ColorScheme _auraColorScheme(AuraColorScheme colors, Brightness brightness) {
  return _auraSurfaceColors(
    _auraContainerColors(_auraBaseColorScheme(colors, brightness), colors),
    colors,
  );
}

ColorScheme _auraBaseColorScheme(
  AuraColorScheme colors,
  Brightness brightness,
) {
  return ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    error: colors.error,
    onError: colors.onError,
    surface: colors.surface,
    onSurface: colors.onSurface,
  );
}

ColorScheme _auraContainerColors(
  ColorScheme colorScheme,
  AuraColorScheme colors,
) {
  return colorScheme.copyWith(
    primaryContainer: colors.primaryVariant,
    onPrimaryContainer: colors.onPrimary,
    secondaryContainer: colors.secondaryVariant,
    onSecondaryContainer: colors.onSecondary,
    tertiary: colors.info,
    onTertiary: colors.onInfo,
  );
}

ColorScheme _auraSurfaceColors(
  ColorScheme colorScheme,
  AuraColorScheme colors,
) {
  final surfaceColors = _auraSurfaceContainerColors(colorScheme, colors);
  final inverseColors = _auraInverseSurfaceColors(surfaceColors, colors);

  return _auraLegacySurfaceColors(inverseColors, colors);
}

ColorScheme _auraSurfaceContainerColors(
  ColorScheme colorScheme,
  AuraColorScheme colors,
) {
  return colorScheme.copyWith(
    surfaceDim: colors.background,
    surfaceBright: colors.surfaceVariant,
    surfaceContainer: colors.surface,
    surfaceContainerHigh: colors.surfaceVariant,
    surfaceContainerHighest: colors.surfaceVariant,
    onSurfaceVariant: colors.onSurfaceVariant,
    outline: colors.outline,
    outlineVariant: colors.outlineVariant,
  );
}

ColorScheme _auraInverseSurfaceColors(
  ColorScheme colorScheme,
  AuraColorScheme colors,
) {
  return colorScheme.copyWith(
    shadow: colors.shadow,
    scrim: colors.scrim,
    inverseSurface: colors.onSurface,
    onInverseSurface: colors.surface,
    inversePrimary: colors.primaryVariant,
    surfaceTint: colors.primary,
  );
}

ColorScheme _auraLegacySurfaceColors(
  ColorScheme colorScheme,
  AuraColorScheme colors,
) {
  return colorScheme.copyWith(
    // ignore: deprecated_member_use - Required for legacy Material fallbacks.
    background: colors.background,
    // ignore: deprecated_member_use - Required for legacy Material fallbacks.
    onBackground: colors.onBackground,
  );
}

ChipThemeData _auraChipTheme(_AuraThemeParts parts) {
  final baseTheme = _auraBaseChipTheme(
    parts.colors,
    parts.auraTheme,
    parts.brightness,
  );

  return _auraChipLabels(baseTheme, parts.colors, parts.textTheme);
}

ChipThemeData _auraChipLabels(
  ChipThemeData baseTheme,
  AuraColorScheme colors,
  TextTheme textTheme,
) => baseTheme.copyWith(
  labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
  secondaryLabelStyle: textTheme.labelMedium?.copyWith(
    color: colors.onSecondary,
  ),
);

ChipThemeData _auraBaseChipTheme(
  AuraColorScheme colors,
  AuraTheme auraTheme,
  Brightness brightness,
) {
  return const ChipThemeData().copyWith(
    backgroundColor: colors.surfaceVariant,
    disabledColor: colors.outlineVariant,
    selectedColor: colors.primary,
    secondarySelectedColor: colors.secondary,
    padding: _auraChipPadding(auraTheme),
    shape: _auraChipShape(colors, auraTheme),
    brightness: brightness,
  );
}

EdgeInsets _auraChipPadding(AuraTheme auraTheme) {
  return EdgeInsets.symmetric(
    vertical: auraTheme.spacing.xs,
    horizontal: auraTheme.spacing.sm,
  );
}

RoundedRectangleBorder _auraChipShape(
  AuraColorScheme colors,
  AuraTheme auraTheme,
) {
  return RoundedRectangleBorder(
    side: .new(color: colors.outlineVariant),
    borderRadius: BorderRadius.all(.circular(auraTheme.borderRadius.full)),
  );
}

DialogThemeData _auraDialogTheme(
  AuraColorScheme colors,
  AuraTheme auraTheme,
  TextTheme textTheme,
) {
  final baseTheme = _auraBaseDialogTheme(colors, auraTheme);

  return baseTheme.copyWith(
    titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
    contentTextStyle: textTheme.bodyMedium?.copyWith(
      color: colors.onSurfaceVariant,
    ),
  );
}

DialogThemeData _auraBaseDialogTheme(
  AuraColorScheme colors,
  AuraTheme auraTheme,
) {
  return DialogThemeData(
    backgroundColor: colors.surface,
    shadowColor: colors.shadow,
    surfaceTintColor: colors.surface,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(.circular(auraTheme.borderRadius.xl)),
    ),
    iconColor: colors.primary,
    barrierColor: colors.scrim,
  );
}

IconButtonThemeData _auraIconButtonTheme(AuraColorScheme colors) {
  return IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: colors.onSurfaceVariant,
      disabledForegroundColor: colors.outline,
      hoverColor: colors.surfaceVariant,
      focusColor: colors.surfaceVariant,
      highlightColor: colors.outlineVariant,
    ),
  );
}

ProgressIndicatorThemeData _auraProgressIndicatorTheme(AuraColorScheme colors) {
  return ProgressIndicatorThemeData(
    color: colors.primary,
    linearTrackColor: colors.outlineVariant,
    circularTrackColor: colors.outlineVariant,
  );
}

SnackBarThemeData _auraSnackBarTheme(
  AuraColorScheme colors,
  AuraTheme auraTheme,
  TextTheme textTheme,
) {
  return SnackBarThemeData(
    backgroundColor: colors.onSurface,
    actionTextColor: colors.primary,
    disabledActionTextColor: colors.outline,
    contentTextStyle: _auraSnackBarTextStyle(colors, textTheme),
    shape: _auraSnackBarShape(auraTheme),
    behavior: .floating,
  );
}

TextStyle? _auraSnackBarTextStyle(AuraColorScheme colors, TextTheme textTheme) {
  return textTheme.bodyMedium?.copyWith(color: colors.surface);
}

ShapeBorder _auraSnackBarShape(AuraTheme auraTheme) {
  return RoundedRectangleBorder(
    borderRadius: BorderRadius.all(.circular(auraTheme.borderRadius.lg)),
  );
}

TextTheme _auraTextTheme(AuraTheme auraTheme, Brightness brightness) {
  final typography = auraTheme.typography;
  final bodyParts = (
    smallSize: typography.fontSizeSm,
    extraSmallSize: typography.fontSizeXs,
    mediumWeight: typography.fontWeightMedium,
  );

  return _auraBaseTextTheme(auraTheme, brightness)
      .merge(_auraDisplayTextTheme(auraTheme))
      .merge(_auraHeadingTextTheme(auraTheme))
      .merge(_auraBodyTextTheme(auraTheme, bodyParts));
}

typedef _AuraBodyTextParts = ({
  double smallSize,
  double extraSmallSize,
  FontWeight mediumWeight,
});

TextTheme _auraBaseTextTheme(AuraTheme auraTheme, Brightness brightness) {
  return _auraDefaultTextTheme(brightness).apply(
    bodyColor: auraTheme.colors.onSurface,
    displayColor: auraTheme.colors.onSurface,
    fontFamily: auraTheme.typography.bodyFontFamily,
  );
}

TextTheme _auraDefaultTextTheme(Brightness brightness) {
  return brightness == Brightness.dark
      ? Typography.material2021().white
      : Typography.material2021().black;
}

TextTheme _auraDisplayTextTheme(AuraTheme auraTheme) {
  return TextTheme(
    displayLarge: _auraTextStyle(auraTheme, auraTheme.typography.fontSize5Xl),
    displayMedium: _auraTextStyle(auraTheme, auraTheme.typography.fontSize4Xl),
    displaySmall: _auraTextStyle(auraTheme, auraTheme.typography.fontSize3Xl),
  );
}

TextTheme _auraHeadingTextTheme(AuraTheme auraTheme) {
  return _auraHeadlineTextTheme(auraTheme)
      .merge(_auraTitleTextTheme(auraTheme));
}

TextTheme _auraHeadlineTextTheme(AuraTheme auraTheme) {
  return TextTheme(
    headlineLarge: _auraTextStyle(auraTheme, auraTheme.typography.fontSize3Xl),
    headlineMedium: _auraTextStyle(auraTheme, auraTheme.typography.fontSize2Xl),
    headlineSmall: _auraTextStyle(auraTheme, auraTheme.typography.fontSizeXl),
  );
}

TextTheme _auraTitleTextTheme(AuraTheme auraTheme) {
  return TextTheme(
    titleLarge: _auraTextStyle(
      auraTheme,
      auraTheme.typography.fontSizeLg,
      fontWeight: auraTheme.typography.fontWeightSemibold,
    ),
    titleMedium: _auraTextStyle(
      auraTheme,
      auraTheme.typography.fontSizeBase,
      fontWeight: auraTheme.typography.fontWeightMedium,
    ),
  );
}

TextTheme _auraBodyTextTheme(AuraTheme auraTheme, _AuraBodyTextParts parts) {
  return _auraBodyContentTextTheme(
    auraTheme,
    parts,
  ).merge(_auraLabelTextTheme(auraTheme, parts));
}

TextTheme _auraBodyContentTextTheme(
  AuraTheme auraTheme,
  _AuraBodyTextParts parts,
) {
  return TextTheme(
    titleSmall: _auraTextStyle(
      auraTheme,
      parts.smallSize,
      fontWeight: parts.mediumWeight,
    ),
    bodyLarge: _auraTextStyle(auraTheme, auraTheme.typography.fontSizeBase),
    bodyMedium: _auraTextStyle(auraTheme, parts.smallSize),
    bodySmall: _auraTextStyle(auraTheme, parts.extraSmallSize),
  );
}

TextTheme _auraLabelTextTheme(AuraTheme auraTheme, _AuraBodyTextParts parts) =>
    TextTheme(
      labelLarge: _auraLabelLargeStyle(auraTheme, parts),
      labelMedium: _auraLabelSmallStyle(auraTheme, parts),
      labelSmall: _auraLabelSmallStyle(auraTheme, parts),
    );

TextStyle _auraLabelLargeStyle(AuraTheme auraTheme, _AuraBodyTextParts parts) =>
    _auraTextStyle(auraTheme, parts.smallSize, fontWeight: parts.mediumWeight);

TextStyle _auraLabelSmallStyle(AuraTheme auraTheme, _AuraBodyTextParts parts) =>
    _auraTextStyle(
      auraTheme,
      parts.extraSmallSize,
      fontWeight: parts.mediumWeight,
    );

TextStyle _auraTextStyle(
  AuraTheme auraTheme,
  double fontSize, {
  FontWeight? fontWeight,
}) {
  return TextStyle(
    color: auraTheme.colors.onSurface,
    fontSize: fontSize,
    fontWeight: fontWeight ?? auraTheme.typography.fontWeightRegular,
    letterSpacing: auraTheme.typography.letterSpacingNormal,
    fontFamily: auraTheme.typography.bodyFontFamily,
  );
}
