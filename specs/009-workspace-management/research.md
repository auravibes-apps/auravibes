# Research: Workspace Management

**Date**: 2026-04-30  
**Feature**: Workspace Management (009-workspace-management)  
**Purpose**: Resolve technical unknowns and document decisions for implementation planning.

---

## Decision: Reuse Existing Workspace Data Layer

**Decision**: Use the existing `WorkspaceRepository`, `WorkspaceDao`, `Workspaces` table, and providers. No new database migrations or entities.

**Rationale**: The codebase already has a complete workspace persistence layer:

- `WorkspaceEntity` (Freezed) with `id`, `name`, `type`, `url`, `createdAt`, `updatedAt`
- `Workspaces` Drift table with auto-generated UUIDv7 IDs
- `WorkspaceRepository` with CRUD, validation, and search
- `allWorkspacesProvider` (keepAlive FutureProvider)
- Default workspace seeded on first launch

**Alternatives considered**:

- Add a new `ActiveWorkspace` table or column — **rejected**: The URL already carries the active workspace ID, and redirect logic handles invalid/missing IDs.
- Redesign workspace model — **rejected**: Existing model already supports name, type, and URL. No gaps identified.

---

## Decision: Sidebar Dropdown for Workspace Switching

**Decision**: Add a dropdown widget to the sidebar header area (replacing or augmenting the app logo) that displays the active workspace and opens a list of all workspaces.

**Rationale**:

- The sidebar header (`_AppLogo` in `AuraSidebarWrapper`) is the most visible and conventional location for a workspace switcher.
- `AuraSidebar` already accepts a `header` widget, making integration straightforward.
- Dropdown pattern is standard for context switching (e.g., Slack, VS Code).

**Alternatives considered**:

- Separate workspace switcher in the app bar — **rejected**: The app uses a sidebar-centric layout; app bar workspace switcher would be less discoverable.
- Bottom sheet or modal for switching — **rejected**: Adds an extra tap; dropdown is faster for frequent actions.

---

## Decision: Full-Screen Management Page (Not Modal)

**Decision**: Implement workspace management as a full-screen route (e.g., `/workspaces/:workspaceId/settings/workspaces` or a dedicated top-level route) rather than a modal/dialog.

**Rationale**:

- Full screen provides more space for the list, inline editing, and clear action buttons.
- Aligns with existing settings/tools screens which are full-page routes.
- Modal would feel cramped for a list with create/edit/delete actions.

**Alternatives considered**:

- Modal bottom sheet — **rejected**: Better for quick single actions, not a full management interface.
- Inline editing in the dropdown — **rejected**: Dropdowns should be for selection only; editing/deletion in a dropdown is poor UX.

---

## Decision: Loading Guard with Debounce

**Decision**: Use a dedicated Riverpod provider (`workspaceSwitcherProvider`) to track switch state (idle/loading/error). Debounce rapid dropdown selections by canceling pending switches that haven't started.

**Rationale**:

- Prevents race conditions when users click multiple workspaces quickly.
- Loading state blocks the UI from initiating another switch.
- If a switch fails, the provider remains in an error state with the previous workspace active, enabling a retry.

**Alternatives considered**:

- Simple `setState` loading flag — **rejected**: Not reusable across the sidebar and other potential switch entry points.
- Queue switches — **rejected**: Unnecessary complexity; users expect only the last selection to take effect.

---

## Decision: Cascade Delete on Workspace Deletion

**Decision**: When deleting a workspace, cascade-delete all related data by `workspaceId` from: `Conversations`, `Tools`, `ToolsGroups`, `McpServers`, `ModelConnections`.

**Rationale**:

- Spec explicitly states: "just need to delete the related data to that workspace" with no draft/pending checks.
- Existing tables already have `workspaceId` foreign keys.
- The `WorkspaceRepository.delete()` method should be verified to handle cascading or call related DAOs.

**Alternatives considered**:

- Soft delete (mark as deleted) — **rejected**: Spec requires permanent removal; no undo needed.
- Manual per-table deletion in the provider — **rejected**: Should live in the repository/DAO layer, not the UI state layer.

---

## Decision: Non-Unique Workspace Names

**Decision**: Workspace names are NOT required to be unique. Only length validation (3–20 chars) is enforced.

**Rationale**:

- User explicitly clarified: "workspaces names are not unique".
- Uniqueness is not functionally required because workspaces are identified by UUID, not name.
- Name collisions are a user organization issue, not a technical constraint.

---

## Open Questions Resolved

| Question                                      | Resolution                                                                             |
| --------------------------------------------- | -------------------------------------------------------------------------------------- |
| Does the workspace model need new fields?     | No — `name` is sufficient for create/edit.                                             |
| Where does the dropdown go in the sidebar?    | Header area of `AuraSidebarWrapper`, replacing/augmenting `_AppLogo`.                  |
| How to prevent deleting the active workspace? | Block deletion in UI; require switching first. Also block deleting the last workspace. |
| How to handle switch failure?                 | Keep current workspace, show error, offer retry.                                       |
| How to handle rapid clicks?                   | Debounce — process only last selection, cancel pending.                                |

---

## Technology References

- Riverpod code generation (`@riverpod`, `@Riverpod(keepAlive: true)`) — existing project pattern.
- Drift DAO pattern — existing in `WorkspaceDao`.
- GoRouter typed routes — existing routing pattern with `workspaceId` path parameter.
- `auravibes_ui` component usage — `AuraSidebar` accepts `header`, `middleSection`, `footer`.
- `AsyncValue` for async UI state — existing pattern for loading/error/data.
