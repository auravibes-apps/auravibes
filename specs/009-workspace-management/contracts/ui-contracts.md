# UI Component Contracts

**Feature**: Workspace Management (009-workspace-management)

---

## WorkspaceDropdown

A dropdown button that displays the active workspace and allows switching.

### Props / Parameters

| Name              | Type                            | Required | Description                            |
| ----------------- | ------------------------------- | -------- | -------------------------------------- |
| `workspaces`      | `List<WorkspaceEntity>`         | Yes      | All available workspaces               |
| `activeWorkspace` | `WorkspaceEntity?`              | Yes      | Currently selected workspace           |
| `onSelected`      | `ValueChanged<WorkspaceEntity>` | Yes      | Called when user selects a workspace   |
| `isLoading`       | `bool`                          | No       | Whether a switch is in progress        |
| `errorMessage`    | `String?`                       | No       | Error to display if last switch failed |

### Behavior

- Displays `activeWorkspace.name` as the button label.
- When tapped, opens a dropdown menu listing all `workspaces`.
- The active workspace item should be visually distinct (e.g., checkmark, bold).
- If `isLoading` is true, shows a loading indicator and disables selection.
- If `errorMessage` is non-null, shows the error inline or below the dropdown.

### Accessibility

- Must be reachable via keyboard.
- Must announce workspace name on selection.

---

## WorkspaceManagementScreen

A full-screen page for listing, creating, editing, and deleting workspaces.

### Props / Parameters

| Name                | Type                                | Required | Description                           |
| ------------------- | ----------------------------------- | -------- | ------------------------------------- |
| `workspaces`        | `AsyncValue<List<WorkspaceEntity>>` | Yes      | List of all workspaces                |
| `onCreate`          | `ValueChanged<String>`              | Yes      | Called with the new workspace name    |
| `onEdit`            | `Function(String id, String name)`  | Yes      | Called with workspace ID and new name |
| `onDelete`          | `ValueChanged<String>`              | Yes      | Called with workspace ID to delete    |
| `isCreating`        | `bool`                              | No       | Whether a create is in progress       |
| `isEditing`         | `String?`                           | No       | ID of workspace being edited          |
| `isDeleting`        | `String?`                           | No       | ID of workspace being deleted         |
| `validationError`   | `String?`                           | No       | Current validation error to display   |
| `activeWorkspaceId` | `String`                            | Yes      | ID of the currently active workspace  |

### Behavior

- Displays a scrollable list of workspaces.
- Each row shows the workspace name and edit/delete actions.
- The active workspace row should not show a delete action.
- If only one workspace exists, no row should show a delete action.
- Tapping "Create" reveals an inline form or navigates to a create form.
- Tapping "Edit" reveals an inline form pre-filled with the current name.
- Tapping "Delete" shows a confirmation dialog.
- Displays `validationError` when name validation fails.

### Accessibility

- All actions (create, edit, delete) must have semantic labels.
- Delete confirmation must be announced to screen readers.
