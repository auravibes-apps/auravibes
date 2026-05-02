# Implementation Plan: Workspace Management

**Branch**: `009-workspace-management` | **Date**: 2026-04-30 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `specs/009-workspace-management/spec.md`

## Summary

Add workspace switching, creation, editing, and deletion capabilities to the AuraVibes app sidebar and a dedicated management screen. The app already has a complete workspace data layer (Drift table, repository, DAO, providers) and URL-scoped routing. This feature is primarily UI and state orchestration: a dropdown in the sidebar to switch workspaces with loading guards, and a management screen for CRUD operations.

## Technical Context

**Language/Version**: Dart 3.11+ / Flutter 3.41.4+ (FVM pinned)  
**Primary Dependencies**: Flutter SDK, hooks_riverpod (code generation), go_router, drift, freezed, auravibes_ui  
**Storage**: Drift (SQLite) — `Workspaces` table already exists with `id`, `name`, `type`, `url`, `createdAt`, `updatedAt`  
**Testing**: flutter_test, mocktail, build_runner  
**Target Platform**: macOS, iOS, Android, Web, Linux, Windows  
**Project Type**: Flutter monorepo mobile/desktop app  
**Performance Goals**: Workspace switch <2s (SC-001); CRUD operations <1 min (SC-002)  
**Constraints**: Workspace names 3–20 chars, non-unique, at least 1 workspace must remain, active workspace cannot be deleted  
**Scale/Scope**: Local-first SQLite, single-user app, no workspace limit

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-checked after Phase 1 design._

| Principle                               | Check                                                                                                  | Status  |
| --------------------------------------- | ------------------------------------------------------------------------------------------------------ | ------- |
| I. User Value First                     | Spec has 5 prioritized user stories (P1/P2), independently testable                                    | ✅ Pass |
| II. Layered, Package-Aware Architecture | UI goes in `auravibes_ui` or `apps/auravibes_app`; state in providers; data in existing repository     | ✅ Pass |
| III. UI System First                    | Sidebar and management screen should use `auravibes_ui` tokens/components                              | ✅ Pass |
| IV. Data and State Correctness          | Existing `WorkspaceRepository` + Drift DAO; immutable state via Freezed; `AsyncValue` for async UI     | ✅ Pass |
| V. Risk-Based Quality Gates             | Widget tests for sidebar dropdown and management screen; provider unit tests for switch/debounce logic | ✅ Pass |
| VI. Explicit Failures                   | Switch failure shows error + retry; validation errors show clear messages                              | ✅ Pass |
| VII. Security and Privacy               | No secrets involved; deletion is local data only                                                       | ✅ Pass |
| VIII. Observable Where It Matters       | Workspace switch timing and failure logging                                                            | ✅ Pass |
| IX. Simplicity                          | Reuse existing workspace layer; no new abstractions needed                                             | ✅ Pass |
| X. Dart and Flutter Standards           | Use `fvm`, `dart format`, `very_good_analysis`                                                         | ✅ Pass |

**Re-check after Phase 1**: All gates still pass. No complexity violations.

## Project Structure

### Documentation (this feature)

```text
specs/009-workspace-management/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output
└── tasks.md             # Phase 2 output (created by /speckit.tasks)
```

### Source Code (repository root)

```text
apps/auravibes_app/
├── lib/
│   ├── features/
│   │   └── workspaces/
│   │       ├── providers/
│   │       │   ├── workspace_switcher_provider.dart   # Switch logic + loading guard
│   │       │   └── workspace_management_provider.dart # CRUD orchestration
│   │       └── screens/
│   │           └── workspace_management_screen.dart   # List, create, edit, delete
│   └── widgets/
│       └── app_navigation_wrappers.dart               # Sidebar wrapper (add dropdown)
│
packages/auravibes_ui/
├── lib/
│   └── src/
│       ├── molecules/
│       │   └── workspace_dropdown.dart                # Reusable dropdown widget
│       └── organisms/
│           └── auravibes_sidebar.dart                 # Already exists; may need header slot
```

**Structure Decision**: UI components that are reusable across the app (dropdown) go in `packages/auravibes_ui/`. App-specific composition (sidebar wrapper integration, management screen) stays in `apps/auravibes_app/`. State providers stay in `features/workspaces/providers/` following the existing feature-based organization.

## Complexity Tracking

> No constitution violations. All work reuses existing abstractions.

| Violation | Why Needed | Simpler Alternative Rejected Because |
| --------- | ---------- | ------------------------------------ |
| —         | —          | —                                    |

## Research & Decisions

_See [research.md](research.md) for detailed findings._

### Key Decisions

1. **Reuse existing data layer**: `WorkspaceRepository`, `WorkspaceDao`, `Workspaces` table, and `allWorkspacesProvider` already exist. No new entities or migrations needed.
2. **Sidebar dropdown placement**: Replace or augment the `_AppLogo` header in `AuraSidebarWrapper` with a `WorkspaceDropdown` that shows the active workspace and allows switching.
3. **Loading guard pattern**: Use a `workspaceSwitchingProvider` (StateNotifier/AsyncNotifier) that tracks the switch state. The dropdown debounces selections and shows a loading overlay/spinner while switching.
4. **Management screen navigation**: Add a new GoRouter route (e.g., `/workspaces/:workspaceId/settings/workspaces`) or a modal/dialog for workspace management. Decision: modal is simpler for quick edits; full screen is better for discovery. **Chosen**: full screen via settings or dedicated route for consistency with other management screens.
5. **Deletion strategy**: Cascade delete all rows with matching `workspaceId` from `Conversations`, `Tools`, `ToolsGroups`, `McpServers`, `ModelConnections`. The existing `WorkspaceRepository.delete()` likely handles this; verify.
6. **Name validation**: 3–20 characters, non-unique. Validation logic lives in the provider/notifier before calling repository.

## Data Model

_See [data-model.md](data-model.md) for full details._

**Summary**: No new entities required. The existing `WorkspaceEntity` (id, name, type, url, createdAt, updatedAt) is sufficient. The management screen operates on `WorkspaceToCreate` and `WorkspacePatch` DTOs which already exist. The only addition is a transient UI state model for the switcher (`WorkspaceSwitchState`: idle | loading | error).

## Contracts

_See [contracts/](contracts/) for interface definitions._

**Summary**: This is an internal Flutter app feature with no external API contracts. The relevant "contracts" are:

- **Riverpod provider interfaces**: `workspaceSwitcherProvider`, `workspaceManagementProvider` — documented in code via dartdoc.
- **UI component interface**: `WorkspaceDropdown` accepts `List<WorkspaceEntity>`, `WorkspaceEntity? activeWorkspace`, `ValueChanged<WorkspaceEntity> onSelected`, and optional `bool isLoading`.

## Quickstart

_See [quickstart.md](quickstart.md) for developer onboarding._

**Summary**: After implementation, a developer can verify the feature by:

1. Launching the app and observing the workspace dropdown in the sidebar header.
2. Creating a new workspace from the management screen (accessible via sidebar button).
3. Switching workspaces via the dropdown and confirming URL + content updates.
4. Editing and deleting workspaces from the management screen.
