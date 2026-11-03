import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_app/widgets/aura_legacy_material_bridge.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart'
    as sdk_localizations;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart' as riverpod_misc;

/// Creates a testable widget wrapped with EasyLocalization and Riverpod.
class TestableApp extends StatefulWidget {
  /// Creates a [TestableApp].
  const new({
    required this.child,
    this.overrides = const [],
    this.workspaceId = 'test-workspace',
    this.workspaceSession,
    this.startLocale = const Locale('en'),
    super.key,
  });

  /// The widget under test.
  final Widget child;

  /// Riverpod provider overrides for the test.
  final List<Object> overrides;

  /// Local workspace used by workspace-aware providers.
  final String workspaceId;

  /// Session instance used as the generated provider family argument.
  final WorkspaceSession? workspaceSession;

  /// Locale used by EasyLocalization in the test app.
  final Locale startLocale;

  @override
  State<TestableApp> createState() => _TestableAppState();
}

class _TestableAppState extends State<TestableApp> {
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _container = _createContainer(widget);
  }

  @override
  void didUpdateWidget(covariant TestableApp oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId == widget.workspaceId &&
        oldWidget.workspaceSession == widget.workspaceSession &&
        identical(oldWidget.overrides, widget.overrides)) {
      return;
    }

    final oldContainer = _container;
    _container = _createContainer(widget);
    if (oldContainer != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        oldContainer.dispose();
      });
    }
  }

  ProviderContainer _createContainer(TestableApp app) {
    final session =
        app.workspaceSession ??
        WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: app.workspaceId),
        );
    final sessionWorkspaceId = session.workspace.localWorkspaceId;
    final routeSessionProvider = workspaceSessionForRouteProvider(
      sessionWorkspaceId,
    );
    final hasRouteSessionOverride = app.overrides
        .whereType<riverpod_misc.Override>()
        .any((override) => override.origin == routeSessionProvider);
    return .new(
      overrides: [
        workspaceSessionProvider(session).overrideWithValue(session),
        workspaceSessionForRouteProvider.overrideWith((_, localWorkspaceId) {
          if (localWorkspaceId == sessionWorkspaceId) return session;

          return WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: localWorkspaceId),
          );
        }),
        ...app.overrides.cast(),
        if (!hasRouteSessionOverride)
          routeSessionProvider.overrideWithValue(AsyncData(session)),
      ],
    );
  }

  @override
  void dispose() {
    _container?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return UncontrolledProviderScope(
      container:
          _container ?? (throw StateError('Test app is not initialized')),
      child: EasyLocalization(
        child: Builder(
          builder: (context) => Portal(
            child: MaterialApp(
              home: widget.child,
              builder: (context, child) => AuraThemeScope(
                theme: Theme.of(context).brightness == Brightness.light
                    ? AuraTheme.light
                    : AuraTheme.dark,
                child: AuraLegacyMaterialBridge(
                  child: AuraSnackBarHost(
                    child: child ?? const SizedBox.shrink(),
                  ),
                ),
              ),
              locale: context.locale,
              localizationsDelegates: [
                ...GlobalMaterialLocalizations.delegates,
                sdk_localizations.GlobalMaterialLocalizations.delegate,
                ...context.localizationDelegates,
              ],
              supportedLocales: context.supportedLocales,
            ),
          ),
        ),
        supportedLocales: const [Locale('en'), Locale('es')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: widget.startLocale,
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  }
}
