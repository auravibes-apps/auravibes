import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/settings/providers/theme_provider.dart';
import 'package:auravibes_app/flavors.dart';
import 'package:auravibes_app/main/locale.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/auravibes_sidebar.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show appFlavor;
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await MainLocale.ensureInitialized();

  final container = ProviderContainer()..read(modelSyncServiceProvider);

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MainLocale(child: MyApp()),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeAsync = ref.watch(themeControllerProvider);
    final themeMode = themeAsync.asData?.value.themeMode ?? ThemeMode.system;

    return Portal(
      child: MaterialApp.router(
        title: F.title,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        builder: (context, child) => AuraText(child: child!),
        theme: ThemeData(
          extensions: [
            AuraTheme.light,
          ],
        ),
        darkTheme: ThemeData(
          colorScheme: const ColorScheme.dark(),
          extensions: [
            AuraTheme.dark,
          ],
        ),
        themeMode: themeMode,
        routerConfig: _router,
      ),
    );
  }

  static final GoRouter _router = GoRouter(
    routes: $appRoutes,
    initialLocation: '/home',
    navigatorKey: rootNavigatorKey,
  );
}

class AppLayout extends StatelessWidget {
  const AppLayout({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AuraSidebarWrapper(child: child);
  }
}
