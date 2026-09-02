import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Creates a testable widget wrapped with EasyLocalization and Riverpod.
class TestableApp extends StatefulWidget {
  /// Creates a [TestableApp].
  const new({
    required this.child,
    this.overrides = const [],
    this.workspaceId = 'test-workspace',
    this.workspaceSession,
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

  @override
  State<TestableApp> createState() => _TestableAppState();
}

class _TestableAppState extends State<TestableApp> {
  ProviderContainer? _container;

  @override
  void initState() {
    super.initState();
    final session =
        widget.workspaceSession ??
        WorkspaceSession(
          LocalWorkspaceRef(localWorkspaceId: widget.workspaceId),
        );
    _container = ProviderContainer(
      overrides: [
        workspaceSessionProvider(session).overrideWithValue(session),
        workspaceSessionForRouteProvider.overrideWith((_, _) async => session),
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
      container:
          _container ?? (throw StateError('Test app is not initialized')),
      child: EasyLocalization(
        child: Builder(
          builder: (context) => MaterialApp(
            home: widget.child,
            builder: (context, child) =>
                AuraSnackBarHost(child: child ?? const SizedBox.shrink()),
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
