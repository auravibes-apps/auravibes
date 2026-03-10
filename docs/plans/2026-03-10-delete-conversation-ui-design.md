# Design: Delete Conversation UI

**Date:** 2026-03-10
**Status:** Draft
**Author:** Design session

## Problem

Users cannot delete conversations from the UI, leading to accumulation of unwanted conversations with no way to remove them.

## Solution

Add a three-dot menu to conversation tiles in the sidebar and chat list screen, with a "Delete" option that shows a confirmation dialog before deletion.

## Scope

| Location | Delete UI? | Rationale |
|----------|------------|-----------|
| Sidebar conversations | ✅ Yes | Primary navigation, quick access |
| Chat list screen | ✅ Yes | Full conversation management |
| Home (recent 5) | ❌ No | Keep home clean, limited real estate |

## User Flow

```
Conversation Tile
       │
       ▼
   Tap ⋮ icon ──► Popup Menu
                      │
                      ▼
               Tap "Delete"
                      │
                      ▼
            Confirmation Dialog
                 /          \
            Cancel          Delete
             (close)           │
                               ▼
                      Call deleteConversation()
                               │
                               ▼
                         Conversation removed
```

## UI Components

### 1. Three-Dot Menu Trigger

**Widget:** `AuraIconButton` (ghost variant)

```dart
AuraIconButton(
  icon: Icons.more_vert,
  variant: AuraIconButtonVariant.ghost,
  size: AuraIconSize.small,
  tooltip: 'Options', // TODO: add locale key
  onPressed: () => _menuController.toggle(),
)
```

### 2. Popup Menu

**Widget:** `AuraPopupMenu` + `AuraPopupMenuItem`

```dart
AuraPopupMenu(
  controller: _menuController,
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      AuraPopupMenuItem(
        title: LocaleKeys.conversation_delete.tr(), // TODO: add locale key
        leading: const Icon(Icons.delete_outline),
        onTap: () => _handleDelete(context, ref),
      ),
    ],
  ),
)
```

### 3. Confirmation Dialog

**Pattern:** Follow existing pattern from `tools_group_card.dart` (lines 99-118)

```dart
Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(LocaleKeys.conversation_delete_title.tr()),
      content: Text(LocaleKeys.conversation_delete_confirm.tr()),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const TextLocale(LocaleKeys.common_cancel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          child: const TextLocale(LocaleKeys.common_delete),
        ),
      ],
    ),
  );

  if (confirmed ?? false) {
    await ref.read(conversationsListProvider.notifier)
        .deleteConversation(conversation.id);
  }
}
```

## Files to Modify

| File | Change |
|------|--------|
| `apps/auravibes_app/lib/features/chats/widgets/sidebar_conversations_widget.dart` | Add `⋮` menu + delete handler to `_SidebarConversationTile` |
| `apps/auravibes_app/lib/features/chats/widgets/chat_list_widget.dart` | Add `⋮` menu + delete handler to `_ChatTile` |
| `apps/auravibes_app/lib/i18n/en.yaml` | Add locale keys for delete dialog |
| `apps/auravibes_app/lib/i18n/es.yaml` | Add Spanish translations |

## New Locale Keys

```yaml
# conversation
conversation_delete: "Delete"
conversation_delete_title: "Delete conversation?"
conversation_delete_confirm: "This action cannot be undone."
```

## Technical Notes

1. **Backend is ready:** `deleteConversation()` exists in `ConversationsList` provider → repository → DAO
2. **No new dependencies:** Uses existing `AuraPopupMenu` and Material `AlertDialog`
3. **Consistent pattern:** Follows same confirmation dialog pattern as `tools_group_card.dart`
4. **State management:** Uses existing Riverpod providers, no new state needed

## Future Improvements

- [ ] Consider creating reusable `AuraConfirmDialog` component to replace raw Material dialogs
- [ ] Add "Undo" snackbar after deletion (optional safety net)
- [ ] Add swipe-to-delete as alternative gesture (mobile-friendly)

## Out of Scope

- Bulk delete multiple conversations
- Archive functionality
- Delete confirmation with conversation title preview
