# Project Structure

## Feature-Based Structure

```
lib/
├── main.dart
├── app.dart
├── core/
│   ├── constants/
│   │   ├── colors.dart
│   │   └── strings.dart
│   ├── theme/
│   │   ├── app_theme.dart
│   │   └── text_styles.dart
│   ├── utils/
│   │   ├── extensions.dart
│   │   └── validators.dart
│   └── errors/
│       └── failures.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── repositories/
│   │   │   └── datasources/
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   └── usecases/
│   │   ├── presentation/
│   │   │   ├── screens/
│   │   │   └── widgets/
│   │   └── providers/
│   │       └── auth_provider.dart
│   └── home/
│       ├── data/
│       ├── domain/
│       ├── presentation/
│       └── providers/
├── shared/
│   ├── widgets/
│   │   ├── buttons/
│   │   ├── inputs/
│   │   └── cards/
│   ├── services/
│   │   ├── api_service.dart
│   │   └── storage_service.dart
│   └── models/
│       └── user.dart
└── routes/
    └── app_router.dart
```

## pubspec.yaml Essentials

```yaml
dependencies:
  flutter:
    sdk: flutter
  # State Management
  hooks_riverpod: 3.4.3
  riverpod_annotation: 4.0.7
  # Navigation
  go_router: ^18.0.0
  # Networking
  dio: ^5.10.0
  # Code Generation
  freezed_annotation: ^3.1.0
  json_annotation: ^4.12.0
  # Storage
  shared_preferences: ^2.5.4

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.16.0
  riverpod_generator: 4.0.9
  freezed: 4.0.1
  json_serializable: ^6.14.0
```

## Feature Layer Responsibilities

| Layer | Responsibility |
|-------|----------------|
| **data/** | API calls, local storage, DTOs |
| **domain/** | Business logic, entities, use cases |
| **presentation/** | UI screens, widgets |
| **providers/** | Riverpod providers for feature |

## Main Entry Point

```dart
// main.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: MyApp()));
}

// app.dart
class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
    );
  }
}
```
