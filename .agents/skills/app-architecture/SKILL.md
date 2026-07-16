---
name: app-architecture
description: "Use when adding, moving, reviewing, or reading code in apps/auravibes_app. Defines the target app architecture for AI agents and humans: feature-first placement, Riverpod boundaries, usecases, repositories, services, adapters, localization, and verification."
---

# App Architecture

Target app architecture for `apps/auravibes_app`. Use this for new code,
migrations, reviews, and architecture cleanup. This is future shape, not a
snapshot of legacy folders.

## First Decision

Before editing, decide the owner:

| Need                                    | Location                                           |
| --------------------------------------- | -------------------------------------------------- |
| Route-level UI                          | `lib/features/<feature>/screens/`                  |
| Feature-only UI                         | `lib/features/<feature>/widgets/`                  |
| Mutable UI/runtime state                | `lib/features/<feature>/notifiers/`                |
| Dependency wiring or read-only state    | `lib/features/<feature>/providers/`                |
| Business rule or workflow               | `lib/features/<feature>/usecases/`                 |
| App-to-engine translation               | `lib/features/<feature>/agent_adapters/`           |
| Feature-only state/model                | `lib/features/<feature>/models/`                   |
| Cross-feature entity/exception/model    | `lib/domain/`                                      |
| Persistence/repository implementation   | `lib/data/`                                        |
| External API, SDK, platform side effect | `lib/services/`                                    |
| Navigation                              | `lib/router/`                                      |
| App-wide provider/notifier/widget       | `lib/providers/`, `lib/notifiers/`, `lib/widgets/` |

If one feature owns the behavior, keep it in that feature. Root folders are for
code used by multiple features or app bootstrap.

## Target Feature Shape

Default path: `lib/features/<feature>/<layer>/<thing>.dart`.

Preferred feature folders:

- `screens/`: route-level UI.
- `widgets/`: feature UI components.
- `notifiers/`: generated Riverpod mutable state classes.
- `providers/`: dependency composition, read-only queries, runtime adapters.
- `usecases/`: business rules, validation, orchestration.
- `agent_adapters/`: app-specific adapters around `auravibes_engine`.
- `models/`: feature-only DTOs, view state, value objects.

Create only the folder needed for the change. Do not add barrels unless the
feature already uses barrels.

## Legacy Rule

Do not reorganize legacy code just because it differs from this shape.

- New files follow target shape.
- Edited legacy files may stay where they are if moving them would enlarge the
  diff.
- Move files only when the task is architecture cleanup, the old placement
  causes the bug, or the move removes duplicated routing/confusion.
- When moving, update imports, generated files, tests, and nearest docs in the
  same change.

## Dependency Direction

UI -> notifiers/providers -> usecases -> repositories/services -> database,
SDKs, platform APIs, `auravibes_engine`.

Never import upward. Never make packages import app code.

## Layer Rules

Screens and widgets:

- Render state and forward user intent.
- Use localized strings only: `TextLocale`, `LocaleKeys`, or `.tr()`.
- Handle `AsyncValue` with switch patterns in new code.
- May read providers/notifiers.
- May call usecases through providers for direct user actions.
- Must not call repositories, Drift DAOs, external SDKs, or engine services.

Notifiers:

- Own loading/selection/editing/queued/runtime state.
- Call usecases or runtime adapters.
- Do not contain validation, persistence decisions, or multi-step workflows.
- Use generated Riverpod classes.
- Keep `build()` for initial state and watched dependencies, not workflows.
- Public methods mutate state or wrap one usecase call with state transitions.

Providers:

- Wire dependencies. Keep bodies boring.
- Providers may expose repositories, services, usecases, streams, computed
  values, and engine adapters.
- Do not hide business rules in providers.
- Provider bodies should be readable in one screen. If not, move logic to a
  usecase, repository, service, or adapter.

Usecases:

- Own business rules, validation, permission decisions, orchestration.
- Prefer feature usecases over root `domain/usecases/`.
- Use root domain usecases only for true cross-feature app behavior.
- Inject repositories/services/adapters. Do not depend on widgets or notifiers.
- Return domain/app results, not widgets, `BuildContext`, or localized strings.
- Avoid one-line pass-throughs. If no rule exists, call the dependency directly.

Repositories:

- Own persistence and data-source coordination.
- Live reads return `Stream`; one-shot reads return `Future`.
- Drift cascades live in schema via `ON DELETE CASCADE`.
- Map database rows before returning to upper layers. Do not leak table rows into
  widgets or usecases unless the repo already uses that legacy pattern.

Services:

- Wrap external/platform/SDK side effects.
- No domain orchestration. Move workflows to usecases.
- Services may translate protocols. They do not choose app workflow policy.

Agent adapters:

- App owns Riverpod, Drift, localization, permissions, persistence, and UI state.
- `auravibes_engine` owns pure agent loop contracts and execution primitives.
- Adapter classes translate app repositories/services/usecases into engine
  provider interfaces.
- Keep adapters thin. If adapter logic becomes app workflow, move it to a
  usecase. If adapter logic becomes app-neutral, move it to engine.

## Riverpod Pattern

- Use generated `@riverpod` or `@Riverpod(keepAlive: true)` providers for new
  Riverpod code.
- Use `@Riverpod(keepAlive: true)` only when state/dependency must survive no
  listeners, streams, or app lifecycle gaps.
- Use plain provider functions for repositories, services, usecases, streams,
  computed values, and runtime adapters.
- Use notifier classes for mutable state only.
- Use `ref.watch` for reactive dependencies and `ref.read` for one-shot actions.
- Avoid provider-to-provider business chains. Put workflow in a usecase.
- Do not add new `.when()` for `AsyncValue`; use Dart switch patterns.

Canonical provider file:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'send_message_usecase_provider.g.dart';

@riverpod
SendMessageUsecase sendMessageUsecase(Ref ref) {
  return SendMessageUsecase(
    conversationRepository: ref.watch(conversationRepositoryProvider),
    agentService: ref.watch(auraAgentServiceProvider),
  );
}
```

Canonical notifier file:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'new_chat_notifier.g.dart';

@riverpod
class NewChatNotifier extends _$NewChatNotifier {
  @override
  NewChatState build() => const NewChatState();

  Future<void> send(String message) async {
    state = state.copyWith(isSending: true);
    try {
      await ref.read(sendMessageUsecaseProvider).call(message: message);
    } finally {
      state = state.copyWith(isSending: false);
    }
  }
}
```

## Models And Domain Types

- Feature `models/`: feature-only state, DTOs, view models, small value objects.
- `domain/entities/`: app concepts shared across features.
- `domain/exceptions/`: typed user-facing failures carrying localization keys.
- Database row/data classes stay behind repositories.
- Engine protocol models stay in `auravibes_engine`; app maps to/from them at
  adapters.
- UI package models must be domain-neutral.

## Naming

- Files use snake_case and role suffixes.
- New usecases: `<verb>_<object>_usecase.dart`, class `VerbObjectUsecase`.
- Existing `UseCase` spelling may stay until touched for nearby work.
- Notifiers: `<name>_notifier.dart`, class `<Name>Notifier`.
- Providers: `<dependency>_provider.dart` for repositories/services/usecases and
  `<thing>_runtime_provider.dart` for runtime adapters.
- Screens: `<feature>_screen.dart` or `<action>_<feature>_screen.dart`.
- Widgets: noun-based names ending in the rendered thing, not `Helper`.
- Avoid `Manager`, `Handler`, `Util`, `Common`, and `Base` unless the existing
  local pattern already requires it.

Canonical usecase file:

```dart
class SendMessageUsecase {
  const SendMessageUsecase({
    required ConversationRepository conversationRepository,
    required AgentRuntime agentRuntime,
  })  : _conversationRepository = conversationRepository,
        _agentRuntime = agentRuntime;

  final ConversationRepository _conversationRepository;
  final AgentRuntime _agentRuntime;

  Future<ConversationEntity> call({required String message}) async {
    final conversation = await _conversationRepository.createMessage(message);
    await _agentRuntime.continueConversation(conversation.id);
    return conversation;
  }
}
```

## Feature Ownership

- `chats`: conversations, agent runtime UI, tool approvals, message flow.
- `skills`: skill definitions, credential forms, skill selection.
- `tools`: MCP/tool source configuration and tool catalog behavior.
- `models`: model/provider selection and model metadata.
- `service_connections`: external service connection setup and credentials UI.
- `settings`: user/workspace preferences.
- `workspaces`: workspace selection and workspace-scoped behavior.

If a change touches two features, prefer one feature owning the usecase and the
other consuming its provider. Move to `domain/` only when ownership is truly
cross-feature and stable.

## AI Coding Rules

- Read target feature folders before editing.
- Reuse existing providers/usecases before adding new ones.
- Add no base classes, generic layers, or package extraction for one caller.
- Fix root cause at the shared layer, not every caller.
- Touch fewest files. Delete or move only when requested or required.
- Prefer one stronger usecase over many micro-usecases.
- Prefer feature-local code over root/shared code until reuse exists.
- Add a new abstraction only when there are at least two current callers or a
  package boundary requires injection.
- Keep public APIs smaller than internal code. App code can be boring and local.

## Tests And Checks

- Business rule change: focused usecase test.
- Notifier state change: notifier/provider test.
- Widget behavior: widget test.
- Drift schema change: migration plus generator.
- Generated source change: run relevant generator, do not hand-edit generated
  files.
- Minimal check: focused test or `fvm dart run melos run validate:quick`.
- Boundary check when moving architecture: search imports for forbidden upward
  dependencies and stale old paths.

Executable boundary checks:

```sh
rg "package:auravibes_app/(data|services)/" apps/auravibes_app/lib/features -g '*.dart'
rg "package:auravibes_app/features/.*/notifiers/" apps/auravibes_app/lib/features/*/usecases -g '*.dart'
rg "BuildContext|\.tr\(|TextLocale|LocaleKeys" apps/auravibes_app/lib/features/*/usecases apps/auravibes_app/lib/domain -g '*.dart'
rg "package:drift|AppDatabase|Dao" apps/auravibes_app/lib/features -g '*.dart'
```

These are tripwires, not automatic failures. Inspect matches and allow legacy or
intentional exceptions only when the current change did not introduce them.

## Architecture Migration Checklist

Use this when applying the skill to old code:

1. Pick one feature or flow. Do not migrate the whole app at once.
2. Identify current owner, target owner, and lowest useful test.
3. Move business rules from widgets/notifiers/providers into usecases.
4. Move app-neutral agent logic from app adapters/services into engine only when
   reuse or dependency isolation is real.
5. Keep UI rendering in screens/widgets and app state in notifiers.
6. Update imports, generated files, and tests in the same patch.
7. Run focused tests first, then `fvm dart run melos run validate:quick` for
   broad moves.
8. Update `doc/architecture/` only when the rule changes, not when code merely
   moves to match the rule.

## Architecture Smells

- Widget imports a repository, Drift database, service client, or engine service.
- Provider body contains branching workflow logic.
- Notifier method coordinates multiple repositories/services without a usecase.
- Usecase only returns `repository.someCall(...)`.
- Service stores app state or chooses product workflow.
- Root `utils/` contains feature concepts.
- Feature model is used by several features but stays feature-local.
- New file lands in root because the feature owner was unclear.

Full docs:

- `doc/architecture/README.md`
- `doc/architecture/target-architecture.md`
- `doc/architecture/usecases-pattern.md`
- `doc/architecture/notifier-pattern.md`
