// ignore_for_file: avoid-non-null-assertion
// Required: Existing nullable API contracts still use explicit assertions.

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
  F.appFlavor = Flavor.values.firstWhere(
    (element) => element.name == appFlavor,
  );
  final _ = WidgetsFlutterBinding.ensureInitialized();
  AppLogging.configure(enabled: F.appFlavor != Flavor.prod);
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
  final _ = container.read(modelSyncServiceProvider);

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
    final themeAsync = ref.watch(themeProvider);
    final routerConfig = ref.watch(routerProvider);
    final themeMode = themeAsync.asData?.value.themeMode ?? ThemeMode.system;

    return Portal(
      child: MaterialApp.router(
        routerConfig: routerConfig,
        builder: (context, child) => AuraText(child: child!),
        title: F.title,
        theme: ThemeData(
          extensions: [
            AuraTheme.light,
          ],
        ),
        darkTheme: ThemeData(
          extensions: [
            AuraTheme.dark,
          ],
          colorScheme: const ColorScheme.dark(),
        ),
        themeMode: themeMode,
        locale: context.locale,
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        debugShowCheckedModeBanner: F.appFlavor != Flavor.prod,
      ),
    );
  }
}
