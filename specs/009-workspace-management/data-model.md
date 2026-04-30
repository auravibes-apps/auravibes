# Data Model: Workspace Management

**Date**: 2026-04-30  
**Feature**: Workspace Management (009-workspace-management)

---

## Existing Entities (No Changes Required)

### WorkspaceEntity

Already defined in the codebase. Sufficient for this feature.

| Field       | Type               | Constraints                     | Notes                                  |
| ----------- | ------------------ | ------------------------------- | -------------------------------------- |
| `id`        | `String` (UUID v7) | Primary key, auto-generated     | Used in URLs and FK references         |
| `name`      | `String`           | 3–20 characters (UI validation) | User-editable only field               |
| `type`      | `WorkspaceType`    | `.local` or `.remote`           | Existing; not modified by this feature |
| `url`       | `String?`          | Nullable                        | Existing; remote workspace URL         |
| `createdAt` | `DateTime`         | Auto-generated                  | Existing                               |
| `updatedAt` | `DateTime`         | Auto-generated                  | Existing                               |

### WorkspaceToCreate

Existing DTO for creating a workspace.

| Field  | Type            | Constraints          |
| ------ | --------------- | -------------------- |
| `name` | `String`        | Required, 3–20 chars |
| `type` | `WorkspaceType` | Required             |
| `url`  | `String?`       | Optional             |

### WorkspacePatch

Existing DTO for updating a workspace.

| Field  | Type             | Constraints                      |
| ------ | ---------------- | -------------------------------- |
| `name` | `String?`        | Optional, 3–20 chars if provided |
| `type` | `WorkspaceType?` | Optional                         |
| `url`  | `String?`        | Optional                         |

---

## New UI State Entities

### WorkspaceSwitchState

Transient state for the workspace switcher. Not persisted.

| Field             | Type                    | Description                            |
| ----------------- | ----------------------- | -------------------------------------- |
| `status`          | `WorkspaceSwitchStatus` | `idle`, `loading`, `error`             |
| `targetWorkspace` | `WorkspaceEntity?`      | The workspace being switched to        |
| `errorMessage`    | `String?`               | Error description if `status == error` |

```dart
enum WorkspaceSwitchStatus { idle, loading, error }
```

### WorkspaceManagementState

Transient state for the management screen. Not persisted.

| Field             | Type                                | Description                                      |
| ----------------- | ----------------------------------- | ------------------------------------------------ |
| `workspaces`      | `AsyncValue<List<WorkspaceEntity>>` | List of all workspaces                           |
| `isCreating`      | `bool`                              | Whether a create operation is in progress        |
| `isEditing`       | `String?`                           | ID of workspace currently being edited, or null  |
| `isDeleting`      | `String?`                           | ID of workspace currently being deleted, or null |
| `validationError` | `String?`                           | Current validation error message                 |

---

## Relationships

```
WorkspaceEntity (1)
  │
  ├── has many → Conversation (via workspaceId)
  ├── has many → Tool (via workspaceId)
  ├── has many → ToolsGroup (via workspaceId)
  ├── has many → McpServer (via workspaceId)
  └── has many → ModelConnection (via workspaceId)

WorkspaceSwitchState (transient)
  └── references → WorkspaceEntity (targetWorkspace)

WorkspaceManagementState (transient)
  └── references → List<WorkspaceEntity>
```

---

## Validation Rules

| Rule                               | Location               | Enforcement                             |
| ---------------------------------- | ---------------------- | --------------------------------------- |
| Name length 3–20 chars             | UI provider / notifier | Before repository call                  |
| At least 1 workspace remains       | UI provider / notifier | Block delete if count == 1              |
| Active workspace cannot be deleted | UI provider / notifier | Block delete if id == activeWorkspaceId |
| No uniqueness constraint on name   | —                      | Not enforced                            |

---

## State Transitions

### Workspace Switch

```
[idle] --(user selects workspace)--> [loading]
[loading] --(switch succeeds)--> [idle]
[loading] --(switch fails)--> [error]
[error] --(user retries)--> [loading]
[error] --(user dismisses)--> [idle]
```

### Workspace CRUD (Management Screen)

```
[list displayed] --(user taps create)--> [create form shown]
[create form shown] --(save with valid name)--> [list displayed + new item]
[create form shown] --(cancel)--> [list displayed]

[list displayed] --(user taps edit)--> [edit form shown for item]
[edit form shown] --(save with valid name)--> [list displayed + updated item]
[edit form shown] --(cancel)--> [list displayed]

[list displayed] --(user taps delete)--> [confirm dialog]
[confirm dialog] --(confirm)--> [list displayed - removed item]
[confirm dialog] --(cancel)--> [list displayed]
```
