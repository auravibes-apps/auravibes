import 'package:auravibes_app/features/workspaces/models/workspace_ref.dart';
import 'package:auravibes_app/features/workspaces/providers/workspace_session_provider.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart' show ProviderScope;

/// Creates a testable widget wrapped with EasyLocalization and ProviderScope.
class TestableApp extends StatelessWidget {
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

  /// Local workspace used by scoped providers.
  final String workspaceId;

  @override
  Widget build(BuildContext context) {
    return EasyLocalization(
      child: Builder(
        builder: (context) {
          return ProviderScope(
            overrides: [
              workspaceSessionProvider.overrideWithValue(
                WorkspaceSession(
                  LocalWorkspaceRef(localWorkspaceId: workspaceId),
                ),
              ),
              workspaceSessionForRouteProvider.overrideWith(
                (_, _) async => WorkspaceSession(
                  LocalWorkspaceRef(localWorkspaceId: workspaceId),
                ),
              ),
              ...overrides.cast(),
            ],
            child: MaterialApp(
              home: child,
              builder: (context, child) => AuraSnackBarHost(
                child: child ?? const SizedBox.shrink(),
              ),
              locale: context.locale,
              localizationsDelegates: context.localizationDelegates,
              supportedLocales: context.supportedLocales,
            ),
          );
        },
      ),
      supportedLocales: const [Locale('en')],
      path: 'assets/i18n',
      fallbackLocale: const Locale('en'),
      startLocale: const Locale('en'),
      useOnlyLangCode: true,
      useFallbackTranslations: true,
    );
  }
}
