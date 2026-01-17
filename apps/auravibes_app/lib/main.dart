import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/features/settings/providers/theme_provider.dart';
import 'package:auravibes_app/flavors.dart';
import 'package:auravibes_app/main/locale.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show SystemChrome, SystemUiMode, SystemUiOverlayStyle, appFlavor;
import 'package:hooks_riverpod/hooks_riverpod.dart';

Future<void> main() async {
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  WidgetsFlutterBinding.ensureInitialized();
  await MainLocale.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(systemNavigationBarColor: Colors.transparent),
  );
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  final container = ProviderContainer();

  final appDatabase = container.read(
    appDatabaseProvider,
  );

  // Load defaults after the database connection is established
  await appDatabase.initializeWithDefaults();
  container.read(modelSyncServiceProvider);

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
    final routerConfig = ref.watch(routerProvider);
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
        debugShowCheckedModeBanner: F.appFlavor != Flavor.prod,
        themeMode: themeMode,
        routerConfig: routerConfig,
      ),
    );
  }
}
