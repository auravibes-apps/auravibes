# Model and Provider Naming

This document defines the naming conventions for model-related domain concepts in the AuraVibes codebase. It exists because the domain term "provider" (as in "LLM provider like OpenAI") collides with Riverpod's `Provider` suffix, creating ambiguity.

## Philosophy

1. **Business-first base names**: The root name of a provider function/class should describe the business concept, not the technical pattern.
2. **One technical suffix**: Riverpod generator appends `Provider` once. Never include `Provider` in the base name.
3. **No stutter**: Avoid `*ProvidersProvider`, `*CredentialsCredentials*`, `*ProviderProviders*` patterns.
4. **Ecosystem-aligned externally, unambiguous internally**: Use "provider" in user-facing UI, but use precise internal domain terms in code.

## Canonical Domain Terms

| Concept                            | Internal Code Term        | UI Label     | Why                                                            |
| ---------------------------------- | ------------------------- | ------------ | -------------------------------------------------------------- |
| API vendor (OpenAI, Anthropic)     | `ApiModelProvider`        | "Provider"   | Ecosystem standard; disambiguated by context                   |
| User-configured API key + base URL | `ModelConnection`         | "Connection" | Avoids "provider" collision; matches OSS patterns (Open WebUI) |
| Workspace-scoped model selection   | `WorkspaceModelSelection` | "Model"      | Scope-aware; distinguishes from raw API model                  |
| Raw model from API catalog         | `ApiModel`                | "Model"      | External catalog concept                                       |

## Riverpod Naming Rules

### Generated Providers (riverpod_generator)

```dart
// ✅ Good: business base name, generator adds Provider suffix
@riverpod
Future<List<ModelConnectionEntity>> listWorkspaceModelConnections(Ref ref, {required String workspaceId}) => ...;

// ❌ Bad: includes Provider in base name, creates stutter
@riverpod
Future<List<ModelConnectionEntity>> listWorkspaceModelConnectionsProvider(Ref ref) => ...;
// Generates: listWorkspaceModelConnectionsProviderProvider
```

### Manual Providers

```dart
// ✅ Good: exactly one Provider suffix
final modelConnectionRepositoryProvider = Provider<ModelConnectionRepository>(...);

// ❌ Bad: redundant suffix
final modelConnectionRepositoryProviderProvider = Provider<ModelConnectionRepository>(...);
```

## File Naming

| Rule                              | Example                                                                                                                 |
| --------------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
| Singular by default               | `model_connection_repository.dart`                                                                                      |
| Plural only for aggregators       | `model_connection_repositories_providers.dart` (groups multiple repos)                                                  |
| No stutter in `providers/` folder | `workspace_model_connections_providers.dart` (aggregator, avoids `workspace_model_connections_provider_providers.dart`) |
| Generated pair alignment          | `x.dart` + `x.g.dart` always match                                                                                      |

## Rename Map

This table documents the migration from old ambiguous names to current canonical names.

### Entities

| Old Name                             | New Name                                      |
| ------------------------------------ | --------------------------------------------- |
| `CredentialsEntity`                  | `ModelConnectionEntity`                       |
| `CredentialsToCreate`                | `ModelConnectionToCreate`                     |
| `ModelProviderFilter`                | `ModelConnectionFilter`                       |
| `CredentialsModelEntity`             | `WorkspaceModelSelectionEntity`               |
| `CredentialsModelWithProviderEntity` | `WorkspaceModelSelectionWithConnectionEntity` |
| `CredentialModelToCreate`            | `WorkspaceModelSelectionToCreate`             |
| `CredentialsModelsFilter`            | `WorkspaceModelSelectionFilter`               |

### Repositories

| Old Name                      | New Name                            |
| ----------------------------- | ----------------------------------- |
| `CredentialsRepository`       | `ModelConnectionRepository`         |
| `CredentialsModelsRepository` | `WorkspaceModelSelectionRepository` |

### Drift Tables

| Old Name           | New Name                   |
| ------------------ | -------------------------- |
| `Credentials`      | `ModelConnections`         |
| `CredentialModels` | `WorkspaceModelSelections` |

### Provider Files

| Old File                                     | New File                                       |
| -------------------------------------------- | ---------------------------------------------- |
| `model_providers_repository_providers.dart`  | `model_connection_repositories_providers.dart` |
| `credentials_repositories_providers.dart`    | `model_connection_repositories_providers.dart` |
| `add_model_provider_providers.dart`          | `add_model_providers.dart`                     |
| `list_models_providers.dart`                 | `workspace_model_connections_providers.dart`   |
| `workspace_credentials_providers.dart`       | `workspace_model_connections_providers.dart`   |
| `list_chat_models_providers.dart`            | `workspace_model_selections_providers.dart`    |
| `workspace_credential_models_providers.dart` | `workspace_model_selections_providers.dart`    |
| `credentials_providers.dart`                 | `workspace_model_selection_providers.dart`     |

### Provider Functions

| Old Function                    | New Function                        | Generated Provider                          |
| ------------------------------- | ----------------------------------- | ------------------------------------------- |
| `modelProvidersRepository`      | `modelConnectionRepository`         | `modelConnectionRepositoryProvider`         |
| `credentialsRepository`         | `modelConnectionRepository`         | `modelConnectionRepositoryProvider`         |
| `credentialsModelsRepository`   | `workspaceModelSelectionRepository` | `workspaceModelSelectionRepositoryProvider` |
| `listCredentials`               | `listWorkspaceModelConnections`     | `listWorkspaceModelConnectionsProvider`     |
| `listWorkspaceCredentials`      | `listWorkspaceModelConnections`     | `listWorkspaceModelConnectionsProvider`     |
| `listCredentialsCredentials`    | `listWorkspaceModelSelections`      | `listWorkspaceModelSelectionsProvider`      |
| `listWorkspaceCredentialModels` | `listWorkspaceModelSelections`      | `listWorkspaceModelSelectionsProvider`      |
| `credentialsModelById`          | `workspaceModelSelectionById`       | `workspaceModelSelectionByIdProvider`       |
| `modelProvidersNotifier`        | `apiModelProviders`                 | `apiModelProvidersProvider`                 |

## Examples from Codebase

### Repository Provider

```dart
// lib/features/models/providers/model_connection_repositories_providers.dart
@Riverpod(keepAlive: true)
ModelConnectionRepository modelConnectionRepository(Ref ref) {
  return ModelConnectionRepositoryImpl(
    database: ref.watch(appDatabaseProvider),
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}
```

### List Provider

```dart
// lib/features/models/providers/workspace_model_connections_providers.dart
@riverpod
Future<List<ModelConnectionEntity>> listWorkspaceModelConnections(
  Ref ref, {
  required String workspaceId,
}) async {
  final repository = ref.watch(modelConnectionRepositoryProvider);
  return repository.getModelConnections(
    ModelConnectionFilter(workspaces: [workspaceId]),
  );
}
```

### Consumer Widget

```dart
// lib/features/home/widgets/status_bar_widget.dart
final modelsAsync = ref.watch(
  listWorkspaceModelSelectionsProvider(workspaceId: workspaceId),
);
```

## Migration Notes

- **No legacy aliases**: This is not a production app with live data requiring migration. Old names were fully replaced.
- **Historical specs**: The `specs/001-two-step-model-selector/` directory contains the original feature spec with old names. It is preserved as historical documentation but is not the source of truth.
- **Build artifacts**: `.dart_tool/` cache files may contain old names in build metadata. These are regenerated on `build_runner` and can be ignored.

## Future Considerations

If the app grows to support additional provider-like concepts (e.g., MCP servers, image generation services), follow the same pattern:

1. Choose a domain term that avoids "provider" (e.g., `McpServerConnection`, `ImageGenerationService`)
2. Name the repository after the domain term
3. Name the provider function after the domain term
4. Let Riverpod append `Provider` once
