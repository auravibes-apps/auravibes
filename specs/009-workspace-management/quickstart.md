# Developer Quickstart: Workspace Management

**Feature**: Workspace Management (009-workspace-management)  
**Branch**: `009-workspace-management`

---

## Prerequisites

- FVM installed and Flutter 3.41.4+ active
- Melos bootstrapped: `fvm dart run melos bs`
- Code generation up to date: `fvm dart run build_runner build --delete-conflicting-outputs`

---

## How to Verify This Feature

### 1. Launch the App

```bash
cd apps/auravibes_app
fvm flutter run
```

### 2. Observe the Sidebar Dropdown

- The sidebar header should display the current workspace name (e.g., "Default Workspace").
- Tapping the header should open a dropdown listing all workspaces.
- The active workspace should be highlighted or marked in the dropdown.

### 3. Switch Workspaces

- Select a different workspace from the dropdown.
- A loading indicator should appear briefly.
- The URL should update to `/workspaces/:newWorkspaceId/...`.
- The sidebar header should reflect the new workspace name.
- The conversation list (middle section) should update to the new workspace's conversations.

### 4. Open Workspace Management

- Tap the "Manage Workspaces" button in the sidebar (location TBD during implementation — likely footer or near the dropdown).
- A full-screen workspace management page should open.

### 5. Create a Workspace

- Tap "Create Workspace" or the `+` button.
- Enter a name between 3 and 20 characters.
- Tap save. The new workspace should appear in the list.
- Return to the sidebar dropdown — the new workspace should be listed.

### 6. Edit a Workspace

- Tap the edit icon (pencil) next to a workspace in the management list.
- Change the name to another valid name (3–20 chars).
- Tap save. The name should update in the list and in the sidebar dropdown.

### 7. Delete a Workspace

- Tap the delete icon (trash) next to a non-active workspace.
- Confirm the deletion in the dialog.
- The workspace should disappear from the list and the sidebar dropdown.
- All related data (conversations, tools, etc.) should be removed.

### 8. Validation & Edge Cases

- Try creating a workspace with a 2-character name → should show validation error.
- Try creating a workspace with a 21-character name → should show validation error.
- Try deleting the last remaining workspace → should be blocked.
- Try deleting the currently active workspace → should be blocked.
- Rapidly click between workspaces in the dropdown → only the last selection should process.
- Disconnect network (if remote workspaces) or trigger an error → should show error with retry option.

---

## Running Tests

```bash
# All workspace-related tests
fvm flutter test test/features/workspaces/ --no-pub

# Widget tests for sidebar dropdown
fvm flutter test test/widgets/ --no-pub

# Full validation
fvm dart run melos run validate:quick
```

---

## Key Files

| File                                                                                      | Purpose                      |
| ----------------------------------------------------------------------------------------- | ---------------------------- |
| `apps/auravibes_app/lib/features/workspaces/providers/workspace_switcher_provider.dart`   | Switch logic + loading guard |
| `apps/auravibes_app/lib/features/workspaces/providers/workspace_management_provider.dart` | CRUD orchestration           |
| `apps/auravibes_app/lib/features/workspaces/screens/workspace_management_screen.dart`     | Management UI                |
| `apps/auravibes_app/lib/widgets/app_navigation_wrappers.dart`                             | Sidebar wrapper integration  |
| `packages/auravibes_ui/lib/src/molecules/workspace_dropdown.dart`                         | Reusable dropdown widget     |

---

## Troubleshooting

| Issue                           | Solution                                                                            |
| ------------------------------- | ----------------------------------------------------------------------------------- |
| Dropdown not showing workspaces | Check `allWorkspacesProvider` is resolved; verify database has rows                 |
| Switch not updating URL         | Check `workspaceSwitcherProvider` updates GoRouter via `context.go()` or equivalent |
| Delete not removing data        | Verify `WorkspaceRepository.delete()` cascades to related tables                    |
| Validation not triggering       | Check name length validation is in the notifier before repository call              |
