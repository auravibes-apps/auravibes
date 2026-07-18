import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Creates a testable widget wrapped with EasyLocalization and Riverpod.
class TestableApp extends StatefulWidget {
  /// Creates a [TestableApp].
  const TestableApp({
    required this.child,
    this.overrides = const [],
    this.workspaceId = 'test-workspace',
    super.key,
  });

  /// The widget under test.
  final Widget child;

  /// Riverpod provider overrides for the test.
  final List<Object> overrides;

  /// Local workspace used by workspace-aware providers.
  final String workspaceId;

  @override
  State<TestableApp> createState() => _TestableAppState();
}

class _TestableAppState extends State<TestableApp> {
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderContainer(
      overrides: [
        workspaceSessionProvider.overrideWithValue(
          WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: widget.workspaceId),
          ),
        ),
        workspaceSessionForRouteProvider.overrideWith(
          (_, _) async => WorkspaceSession(
            LocalWorkspaceRef(localWorkspaceId: widget.workspaceId),
          ),
        ),
        ...widget.overrides.cast(),
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
      container: _container ??
          (throw StateError('Test app is not initialized')),
      child: EasyLocalization(
        child: Builder(
          builder: (context) => MaterialApp(
            home: widget.child,
            builder: (context, child) => AuraSnackBarHost(
              child: child ?? const SizedBox.shrink(),
            ),
            locale: context.locale,
            localizationsDelegates: context.localizationDelegates,
            supportedLocales: context.supportedLocales,
          ),
        ),
        supportedLocales: const [Locale('en')],
        path: 'assets/i18n',
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        useOnlyLangCode: true,
        useFallbackTranslations: true,
      ),
    );
  }
}
