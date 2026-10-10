import 'dart:async';
import 'dart:math';

import 'package:auravibes_app/app_env_config.dart';
import 'package:auravibes_app/features/models/notifiers/model_catalog_sync_notifier.dart';
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/features/settings/notifiers/app_theme.dart';
import 'package:auravibes_app/flavor.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/main/main_locale.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/services/app_logging.dart';
import 'package:auravibes_app/services/marionette/marionette_extensions.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_app/widgets/friendly_build_error_widget.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode, kIsWeb;
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiOverlayStyle, appFlavor;
import 'package:flutter_driver/driver_extension.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:material_ui/material_ui.dart';

PrintLogCollector? _marionetteLogCollector;

Future<void> main() async {
  _configureFlavor();
  final marionetteInstanceId = _ensureFlutterBinding();
  _configureLogging();
  await MainLocale.ensureInitialized();

  _configureSystemUi();
  final container = ProviderContainer();
  if (marionetteInstanceId != null) {
    MarionetteExtensionRegistration.register(
      MarionetteExtensionBootstrap.createState(container),
    );
  }

  ErrorWidget.builder = (details) => FriendlyBuildErrorWidget(details: details);
  _runApp(container);
  _scheduleModelSync(container);
}

void _configureFlavor() =>
    AppFlavorConfig.instance.setAppFlavor(AppFlavorResolver.resolve(appFlavor));

void _configureLogging() => AppLogging.configure(
  enabled: AppFlavorConfig.instance.appFlavor != Flavor.prod,
  onLog: _marionetteLogCollector?.addLog,
);

String? _ensureFlutterBinding() {
  // Debug-only bridges; enable one explicitly for agent-controlled runs.
  if (_shouldEnableMarionette()) return _initializeMarionette();

  if (kDebugMode && const bool.fromEnvironment('ENABLE_FLUTTER_DRIVER')) {
    final _ = enableFlutterDriverExtension();

    return null;
  }

  final _ = WidgetsFlutterBinding.ensureInitialized();

  return null;
}

bool _shouldEnableMarionette() => MarionetteExtensionBootstrap.shouldEnable(
  isDebugMode: kDebugMode,
  requested: const bool.fromEnvironment('ENABLE_MARIONETTE'),
  flavor: AppFlavorConfig.instance.appFlavor,
  dbHashSource: AppEnvConfig.dbHashSource,
);

String _initializeMarionette() {
  final instanceId = _resolveMarionetteInstanceId();
  final logCollector = PrintLogCollector();
  _marionetteLogCollector = logCollector;
  final _ = MarionetteBinding.ensureInitialized(
    .new(logCollector: logCollector),
  );
  _registerMarionetteInstanceExtension(instanceId);
  debugPrint('AURAVIBES_MARIONETTE_INSTANCE_ID=$instanceId');

  return instanceId;
}

String _resolveMarionetteInstanceId() {
  const configuredInstanceId = String.fromEnvironment(
    'AURAVIBES_MARIONETTE_INSTANCE_ID',
  );
  if (configuredInstanceId.isNotEmpty) return configuredInstanceId;

  final timestamp = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(
    36,
  );
  final nonce = Random.secure().nextInt(1 << 32).toRadixString(36);

  return 'agent-$timestamp-$nonce';
}

void _registerMarionetteInstanceExtension(String instanceId) {
  registerMarionetteExtension(
    name: 'auravibes.instanceIdentity',
    description: 'Returns the identity of the connected AuraVibes instance.',
    inputSchema: const .new(
      title: 'AuraVibes Instance Identity',
      description: 'No arguments. Returns the current launch instance ID.',
    ),
    callback: (_) async =>
        MarionetteExtensionResult.success({'instanceId': instanceId}),
  );
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
    unawaited(
      container
          .read(modelCatalogSyncNotifierProvider.notifier)
          .syncAutomatically(),
    );
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
      hue: hue,
    );
  }
}

ThemeData _auraThemeData(double hue, Brightness brightness) {
  return _auraMaterialTheme(_auraThemeFor(hue, brightness), brightness);
}

AuraTheme _auraThemeFor(double hue, Brightness brightness) {
  final baseTheme = brightness == Brightness.light
      ? AuraTheme.light
      : AuraTheme.dark;

  return baseTheme.copyWith(
    colors: AuraComputedColorScheme(
      primaryHue: hue,
      brightness: brightness == Brightness.light ? .light : .dark,
    ),
  );
}

class const _MaterialAppRoot({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
  required final double hue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext _) {
    return Portal(
      child: _MaterialAppRouter(
        routerConfig: routerConfig,
        lightTheme: lightTheme,
        darkTheme: darkTheme,
        themeMode: themeMode,
        hue: hue,
      ),
    );
  }
}

class const _MaterialAppRouter({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
  required final double hue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return _MaterialAppRouterView(
      routerConfig: routerConfig,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      hue: hue,
    );
  }
}

class const _MaterialAppRouterView({
  required final GoRouter routerConfig,
  required final ThemeData lightTheme,
  required final ThemeData darkTheme,
  required final ThemeMode themeMode,
  required final double hue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final localization = _appLocalization(context);
    final brightness = _effectiveBrightness(themeMode, context);
    final targetAuraTheme = _auraThemeFor(hue, brightness);

    return _AuraMaterialApp(
      routerConfig: routerConfig,
      lightTheme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeMode,
      targetAuraTheme: targetAuraTheme,
      locale: localization.locale,
      delegates: localization.delegates,
      locales: localization.locales,
    );
  }
}

Brightness _effectiveBrightness(ThemeMode themeMode, BuildContext context) =>
    switch (themeMode) {
      .light => .light,
      .dark => .dark,
      .system => MediaQuery.platformBrightnessOf(context),
    };

class _AuraMaterialApp extends MaterialApp {
  new({
    required GoRouter routerConfig,
    required ThemeData lightTheme,
    required ThemeData darkTheme,
    required ThemeMode themeMode,
    required AuraTheme targetAuraTheme,
    required Locale locale,
    required Iterable<LocalizationsDelegate<dynamic>> delegates,
    required Iterable<Locale> locales,
  }) : super.router(
         routerConfig: routerConfig,
         builder: (context, child) => _AuraAppContent(
           router: routerConfig,
           targetAuraTheme: targetAuraTheme,
           child: child,
         ),
         title: AppFlavorConfig.instance.title,
         scrollBehavior: const _AuraScrollBehavior(),
         theme: lightTheme,
         darkTheme: darkTheme,
         themeMode: themeMode,
         locale: locale,
         localizationsDelegates: delegates,
         supportedLocales: locales,
         debugShowCheckedModeBanner: _showDebugBanner,
       );
}

class const _AuraAppContent({
  required final GoRouter router,
  required final AuraTheme targetAuraTheme,
  required final Widget? child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<AuraTheme>(
    tween: _AuraThemeTween(end: targetAuraTheme),
    duration: kThemeAnimationDuration,
    builder: (context, theme, _) => _AuraAppThemeContent(
      router: router,
      theme: theme,
      child: _snackBarBuilder(context, child),
    ),
  );
}

class const _AuraAppThemeContent({
  required final GoRouter router,
  required final AuraTheme theme,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraThemeScope(
    theme: theme,
    child: _RouteTitle(router: router, child: child),
  );
}

class const _RouteTitle({
  required final GoRouter router,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final routeInformationProvider = router.routeInformationProvider;

    return ListenableBuilder(
      listenable: routeInformationProvider,
      builder: (context, _) => _RouteTitleContent(
        path: routeInformationProvider.value.uri.path,
        child: child,
      ),
    );
  }
}

class const _RouteTitleContent({
  required final String path,
  required final Widget child,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final key = RouteTitles.titleKeyForPath(path);
    final appTitle = AppFlavorConfig.instance.title;
    final title = key == null
        ? appTitle
        : '${key.tr(context: context)} - $appTitle';

    return Title(
      title: title,
      color: Theme.of(context).colorScheme.surface,
      child: child,
    );
  }
}

abstract final class RouteTitles {
  static const _workspaceRouteLength = 3;
  static const _moreRouteLength = 4;
  static const _cloudAccountRouteLength = 5;
  static const _workspaceAreaIndex = 2;
  static const _moreSectionIndex = 3;
  static const _cloudAccountScreenIndex = 4;

  static String? titleKeyForPath(String path) {
    if (path == '/') return LocaleKeys.intro_flow_welcome_title;

    final segments = Uri.parse(path).pathSegments;
    if (segments case ['intro', ...]) {
      return LocaleKeys.intro_flow_welcome_title;
    }
    if (segments.length < _workspaceRouteLength ||
        segments.firstOrNull != 'workspaces') {
      return null;
    }

    return switch (segments[_workspaceAreaIndex]) {
      'chat' => LocaleKeys.menu_new_chat,
      'chats' => LocaleKeys.menu_chats,
      'settings' => LocaleKeys.settings_screen_title,
      'more' => _moreTitleKey(segments),
      _ => null,
    };
  }

  static String? _moreTitleKey(List<String> segments) {
    if (segments.length < _moreRouteLength) {
      return LocaleKeys.more_screen_title;
    }

    return switch (segments[_moreSectionIndex]) {
      'manage-workspaces' => LocaleKeys.workspace_management_title,
      'cloud-accounts' => _cloudAccountTitleKey(segments),
      'tools' => LocaleKeys.tools_screen_title,
      'models' => LocaleKeys.models_screens_title,
      'service-connections' => LocaleKeys.service_connections_title,
      'skills' => LocaleKeys.skills_screen_title,
      'skill-credential-definitions' =>
        LocaleKeys.skill_credentials_definitions_title,
      'agents' => LocaleKeys.agents_title,
      _ => null,
    };
  }

  static String _cloudAccountTitleKey(List<String> segments) {
    if (segments.length < _cloudAccountRouteLength) {
      return LocaleKeys.cloud_accounts_title;
    }

    return switch (segments[_cloudAccountScreenIndex]) {
      'login' => LocaleKeys.cloud_accounts_login_existing,
      'register' => LocaleKeys.cloud_accounts_register,
      'forgot-password' => LocaleKeys.cloud_accounts_forgot_password,
      _ => LocaleKeys.cloud_accounts_title,
    };
  }
}

class const _AuraScrollBehavior() extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => Scrollbar(child: child, controller: details.controller);
}

({
  Locale locale,
  Iterable<LocalizationsDelegate<dynamic>> delegates,
  Iterable<Locale> locales,
})
_appLocalization(BuildContext context) {
  return (
    locale: context.locale,
    delegates: [
      ...GlobalMaterialLocalizations.delegates,
      sdk_localizations.GlobalMaterialLocalizations.delegate,
      ...context.localizationDelegates,
    ],
    locales: context.supportedLocales,
  );
}

class _AuraThemeTween extends Tween<AuraTheme> {
  new({required AuraTheme end}) : super(begin: end, end: end);

  @override
  AuraTheme lerp(double t) {
    final begin = this.begin;
    final end = this.end;
    if (begin == null || end == null) return AuraTheme.light;

    return begin.lerp(end, t);
  }
}

Widget Function(BuildContext, Widget?) get _snackBarBuilder {
  return (_, child) =>
      AuraLegacyMaterialBridge(child: _AuraSnackBarHost(child: child));
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

const _noPageTransitionsBuilder = _NoPageTransitionsBuilder();

final _auraPageTransitionsTheme = PageTransitionsTheme(
  builders: {
    ...const PageTransitionsTheme().builders,
    if (kIsWeb) .android: _noPageTransitionsBuilder,
    if (kIsWeb) .iOS: _noPageTransitionsBuilder,
    .macOS: _noPageTransitionsBuilder,
    .windows: _noPageTransitionsBuilder,
    .linux: _noPageTransitionsBuilder,
    .fuchsia: _noPageTransitionsBuilder,
  },
);

ThemeData _buildBaseThemeCore(_AuraThemeParts parts) {
  final colors = parts.colors;
  final foundation = _baseThemeFoundation(parts);

  return _baseThemeInputStyle(
    _baseThemeInteractionColors(foundation, colors),
    colors,
  );
}

ThemeData _baseThemeFoundation(_AuraThemeParts parts) => ThemeData(
  pageTransitionsTheme: _auraPageTransitionsTheme,
  splashFactory: NoSplash.splashFactory,
  useMaterial3: true,
  colorScheme: _auraColorScheme(parts.colors, parts.brightness),
  brightness: parts.brightness,
  fontFamily: parts.auraTheme.typography.bodyFontFamily,
);

ThemeData _baseThemeInteractionColors(
  ThemeData theme,
  AuraColorScheme colors,
) => theme.copyWith(
  focusColor: colors.surfaceVariant,
  highlightColor: Colors.transparent,
  hoverColor: Colors.transparent,
  splashColor: Colors.transparent,
);

ThemeData _baseThemeInputStyle(ThemeData theme, AuraColorScheme colors) {
  final primary = colors.primary;

  return theme.copyWith(
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      splashColor: Colors.transparent,
    ),
    textButtonTheme: .new(
      style: .new(
        overlayColor: _focusOnlyOverlay(colors.surfaceVariant),
        splashFactory: NoSplash.splashFactory,
      ),
    ),
    textSelectionTheme: .new(
      cursorColor: primary,
      selectionColor: primary.withValues(alpha: 0.24),
      selectionHandleColor: primary,
    ),
  );
}

class const _NoPageTransitionsBuilder()
    extends FadeUpwardsPageTransitionsBuilder {
  @override
  Duration get transitionDuration => noTransitionDuration();

  @override
  Duration get reverseTransitionDuration => noTransitionDuration();

  static Duration noTransitionDuration() => Duration.zero;
}

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
    borderRadius: BorderRadius.all(
      .circular(auraTheme.fromBorderRadius(.full)),
    ),
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
      borderRadius: BorderRadius.all(
        .circular(auraTheme.fromBorderRadius(.xl)),
      ),
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
      splashFactory: NoSplash.splashFactory,
    ).copyWith(overlayColor: _focusOnlyOverlay(colors.surfaceVariant)),
  );
}

WidgetStateProperty<Color?> _focusOnlyOverlay(Color focusColor) =>
    WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) return Colors.transparent;
      if (states.contains(WidgetState.focused)) return focusColor;

      return Colors.transparent;
    });

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
    borderRadius: BorderRadius.all(.circular(auraTheme.fromBorderRadius(.lg))),
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
