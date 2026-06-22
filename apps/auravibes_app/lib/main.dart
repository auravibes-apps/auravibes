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
        builder: (context, child) => AuraSnackBarHost(
          child: AuraText(
            child: child ?? const SizedBox.shrink(),
          ),
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
    // ignore: deprecated_member_use - Required for legacy Material fallbacks.
    background: colors.background,
    // ignore: deprecated_member_use - Required for legacy Material fallbacks.
    onBackground: colors.onBackground,
  );

  return ThemeData(
    extensions: [auraTheme],
    useMaterial3: true,
    colorScheme: colorScheme,
    brightness: brightness,
    scaffoldBackgroundColor: colors.background,
    fontFamily: auraTheme.typography.bodyFontFamily,
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
        borderRadius: BorderRadius.all(
          Radius.circular(auraTheme.borderRadius.full),
        ),
      ),
      labelStyle: textTheme.labelMedium?.copyWith(color: colors.onSurface),
      secondaryLabelStyle: textTheme.labelMedium?.copyWith(
        color: colors.onSecondary,
      ),
      brightness: brightness,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      shadowColor: colors.shadow,
      surfaceTintColor: colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(
          Radius.circular(auraTheme.borderRadius.xl),
        ),
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
        borderRadius: BorderRadius.all(
          Radius.circular(auraTheme.borderRadius.lg),
        ),
      ),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

TextTheme _auraTextTheme(AuraTheme auraTheme, Brightness brightness) {
  final colors = auraTheme.colors;
  final baseTheme = brightness == Brightness.dark
      ? Typography.material2021().white
      : Typography.material2021().black;

  return baseTheme
      .apply(
        bodyColor: colors.onSurface,
        displayColor: colors.onSurface,
        fontFamily: auraTheme.typography.bodyFontFamily,
      )
      .copyWith(
        displayLarge: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSize5Xl,
        ),
        displayMedium: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSize4Xl,
        ),
        displaySmall: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSize3Xl,
        ),
        headlineLarge: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSize3Xl,
        ),
        headlineMedium: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSize2Xl,
        ),
        headlineSmall: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSizeXl,
        ),
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
        titleSmall: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSizeSm,
          fontWeight: auraTheme.typography.fontWeightMedium,
        ),
        bodyLarge: _auraTextStyle(auraTheme, auraTheme.typography.fontSizeBase),
        bodyMedium: _auraTextStyle(auraTheme, auraTheme.typography.fontSizeSm),
        bodySmall: _auraTextStyle(auraTheme, auraTheme.typography.fontSizeXs),
        labelLarge: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSizeSm,
          fontWeight: auraTheme.typography.fontWeightMedium,
        ),
        labelMedium: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSizeXs,
          fontWeight: auraTheme.typography.fontWeightMedium,
        ),
        labelSmall: _auraTextStyle(
          auraTheme,
          auraTheme.typography.fontSizeXs,
          fontWeight: auraTheme.typography.fontWeightMedium,
        ),
      );
}

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
