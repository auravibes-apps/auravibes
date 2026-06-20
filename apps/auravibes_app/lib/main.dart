import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/main/main_locale.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/app_log_buffer.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlayStyle, appFlavor;
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  AppFlavorConfig.appFlavor = AppFlavorResolver.resolve(appFlavor);
  final _ = WidgetsFlutterBinding.ensureInitialized();
  AppLogging.configure(enabled: AppFlavorConfig.appFlavor != Flavor.prod);
  await MainLocale.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final container = ProviderContainer();

  final appDatabase = container.read(
    appDatabaseProvider,
  );

  // Load defaults after the database connection is established.
  await appDatabase.initializeWithDefaults();
  final _ = container.read(modelSyncServiceProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainLocale(child: MyApp()),
    ),
  );
}

class AppFlavorResolver {
  AppFlavorResolver._();

  static Flavor resolve(String? flavorName) {
    if (flavorName == null) {
      throw StateError('appFlavor is not initialized');
    }

    return Flavor.values.byName(flavorName);
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeProvider);
    final routerConfig = ref.watch(routerProvider);
    final themeMode = themeAsync.asData?.value.themeMode ?? ThemeMode.system;

    return Portal(
      child: MaterialApp.router(
        routerConfig: routerConfig,
        builder: (context, child) => AuraText(
          child: child ?? const SizedBox.shrink(),
        ),
        title: AppFlavorConfig.title,
        theme: _auraMaterialTheme(AuraTheme.light, Brightness.light),
        darkTheme: _auraMaterialTheme(AuraTheme.dark, Brightness.dark),
        themeMode: themeMode,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        debugShowCheckedModeBanner: AppFlavorConfig.appFlavor != Flavor.prod,
      ),
    );
  }
}

ThemeData _auraMaterialTheme(AuraTheme auraTheme, Brightness brightness) {
  final colors = auraTheme.colors;
  final typography = auraTheme.typography;
  final textTheme = _auraTextTheme(auraTheme, brightness);
  final colorScheme = ColorScheme(
    brightness: brightness,
    primary: colors.primary,
    onPrimary: colors.onPrimary,
    primaryContainer: colors.primaryVariant,
    onPrimaryContainer: colors.onPrimary,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    secondaryContainer: colors.secondaryVariant,
    onSecondaryContainer: colors.onSecondary,
    tertiary: colors.info,
    onTertiary: colors.onInfo,
    error: colors.error,
    onError: colors.onError,
    surface: colors.surface,
    onSurface: colors.onSurface,
    surfaceDim: colors.background,
    surfaceBright: colors.surfaceVariant,
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

  return ThemeData(
    extensions: [auraTheme],
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    fontFamily: typography.fontFamily,
    iconTheme: IconThemeData(color: colors.onSurfaceVariant),
    primaryTextTheme: textTheme,
    textTheme: textTheme,
    chipTheme: ChipThemeData(
      backgroundColor: colors.surfaceVariant,
      disabledColor: colors.outlineVariant,
      selectedColor: colors.primary,
      secondarySelectedColor: colors.secondary,
      padding: EdgeInsets.symmetric(
        vertical: auraTheme.spacing.xs,
        horizontal: auraTheme.spacing.sm,
      ),
      shape: RoundedRectangleBorder(
        side: BorderSide(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(auraTheme.borderRadius.full),
      ),
      labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: colors.onPrimary,
      ),
      brightness: brightness,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shadowColor: colors.shadow,
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(auraTheme.borderRadius.xl),
      ),
      iconColor: colors.primary,
      titleTextStyle: textTheme.titleLarge?.copyWith(color: colors.onSurface),
      contentTextStyle: textTheme.bodyMedium?.copyWith(
        color: colors.onSurfaceVariant,
      ),
      barrierColor: colors.scrim,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        foregroundColor: colors.onSurfaceVariant,
        disabledForegroundColor: colors.outline,
        hoverColor: colors.surfaceVariant,
        focusColor: colors.surfaceVariant,
        highlightColor: colors.outlineVariant,
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.primary,
      linearTrackColor: colors.outlineVariant,
      circularTrackColor: colors.outlineVariant,
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.onSurface,
      actionTextColor: colors.primary,
      disabledActionTextColor: colors.outline,
      contentTextStyle: textTheme.bodyMedium?.copyWith(color: colors.surface),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(auraTheme.borderRadius.lg),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _auraTextTheme(AuraTheme auraTheme, Brightness brightness) {
  final typography = auraTheme.typography;
  final colors = auraTheme.colors;
  final textColor = brightness == Brightness.dark
      ? colors.onSurface
      : colors.onBackground;
  final baseTheme = brightness == Brightness.dark
      ? Typography.material2021().white
      : Typography.material2021().black;

  return baseTheme
      .apply(
        bodyColor: textColor,
        displayColor: textColor,
        fontFamily: typography.fontFamily,
      )
      .copyWith(
        displayLarge: _auraTextStyle(auraTheme, typography.sizes.xl5),
        displayMedium: _auraTextStyle(auraTheme, typography.sizes.xl4),
        displaySmall: _auraTextStyle(auraTheme, typography.sizes.xl3),
        headlineLarge: _auraTextStyle(auraTheme, typography.sizes.xl3),
        headlineMedium: _auraTextStyle(auraTheme, typography.sizes.xl2),
        headlineSmall: _auraTextStyle(auraTheme, typography.sizes.xl),
        titleLarge: _auraTextStyle(
          auraTheme,
          typography.sizes.lg,
          fontWeight: typography.weights.semibold,
        ),
        titleMedium: _auraTextStyle(
          auraTheme,
          typography.sizes.base,
          fontWeight: typography.weights.medium,
        ),
        titleSmall: _auraTextStyle(
          auraTheme,
          typography.sizes.sm,
          fontWeight: typography.weights.medium,
        ),
        bodyLarge: _auraTextStyle(auraTheme, typography.sizes.base),
        bodyMedium: _auraTextStyle(auraTheme, typography.sizes.sm),
        bodySmall: _auraTextStyle(auraTheme, typography.sizes.xs),
        labelLarge: _auraTextStyle(
          auraTheme,
          typography.sizes.sm,
          fontWeight: typography.weights.medium,
        ),
        labelMedium: _auraTextStyle(
          auraTheme,
          typography.sizes.xs,
          fontWeight: typography.weights.medium,
        ),
        labelSmall: _auraTextStyle(
          auraTheme,
          typography.sizes.xs,
          fontWeight: typography.weights.medium,
        ),
      );
}

TextStyle _auraTextStyle(
  AuraTheme auraTheme,
  double fontSize, {
  FontWeight? fontWeight,
}) {
  final typography = auraTheme.typography;

  return TextStyle(
    color: auraTheme.colors.onSurface,
    fontSize: fontSize,
    fontWeight: fontWeight ?? typography.weights.regular,
    letterSpacing: typography.letterSpacings.normal,
    fontFamily: typography.fontFamily,
  );
}
