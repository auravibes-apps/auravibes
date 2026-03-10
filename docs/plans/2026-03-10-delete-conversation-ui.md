# Delete Conversation UI Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Add a three-dot menu to conversation tiles in sidebar and chat list screen, with "Delete" option and confirmation dialog.

**Architecture:** Wrap existing `_SidebarConversationTile` and `_ChatTile` with `AuraPopupMenu` triggered by `AuraIconButton`. Use existing `AlertDialog` pattern with confirmation before calling `deleteConversation()` provider.

**Tech Stack:** Flutter, Riverpod, AuraVibes UI components, easy_localization

---

## Task 1: Add Locale Keys for Delete Dialog

**Files:**
- Modify: `apps/auravibes_app/assets/i18n/en.json`
- Modify: `apps/auravibes_app/assets/i18n/es.json`

**Step 1: Add English translations**

Edit `apps/auravibes_app/assets/i18n/en.json`, add inside `chats_screens` object (after line 61):

```json
    "chat_conversation": {
      "select_model_selctor": "Select Model",
      "message_placeholder": "Type your message...",
      "waiting_for_tools": "Waiting for tools to connect...",
      "waiting_for_tools_named": "Waiting for {tools} to connect...",
      "delete_title": "Delete Conversation",
      "delete_confirm": "Are you sure you want to delete this conversation? This action cannot be undone.",
      "delete_tooltip": "Delete conversation"
    }
```

**Step 2: Add Spanish translations**

Edit `apps/auravibes_app/assets/i18n/es.json`, add inside `chats_screens` object (after line 61):

```json
    "chat_conversation": {
      "select_model_selctor": "Selecionar Modelo",
      "message_placeholder": "Escribe tu mensaje...",
      "waiting_for_tools": "Esperando a que las herramientas se conecten...",
      "waiting_for_tools_named": "Esperando a que {tools} se conecte...",
      "delete_title": "Eliminar Conversación",
      "delete_confirm": "¿Estás seguro de que deseas eliminar esta conversación? Esta acción no se puede deshacer.",
      "delete_tooltip": "Eliminar conversación"
    }
```

**Step 3: Regenerate locale keys**

Run:
```bash
cd apps/auravibes_app && fvm flutter pub run easy_localization:generate -S assets/i18n/ -O lib/i18n
```

Expected: `lib/i18n/locale_keys.dart` updated with new keys:
- `chats_screens_chat_conversation_delete_title`
- `chats_screens_chat_conversation_delete_confirm`
- `chats_screens_chat_conversation_delete_tooltip`

**Step 4: Commit**

```bash
git add apps/auravibes_app/assets/i18n/en.json apps/auravibes_app/assets/i18n/es.json apps/auravibes_app/lib/i18n/locale_keys.dart
git commit -m "feat(i18n): add delete conversation locale keys"
```

---

## Task 2: Add Delete to Sidebar Conversation Tile

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/widgets/sidebar_conversations_widget.dart`

**Step 1: Convert `_SidebarConversationTile` to ConsumerStatefulWidget**

Replace the `_SidebarConversationTile` class (lines 138-177) with:

```dart
class _SidebarConversationTile extends ConsumerStatefulWidget {
  const _SidebarConversationTile({
    required this.chat,
    required this.isActive,
  });

  final ConversationEntity chat;
  final bool isActive;

  @override
  ConsumerState<_SidebarConversationTile> createState() =>
      _SidebarConversationTileState();
}

class _SidebarConversationTileState
    extends ConsumerState<_SidebarConversationTile> {
  final _menuController = AuraPopupMenuController();

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.chats_screens_chat_conversation_delete_title.tr()),
        content: Text(LocaleKeys.chats_screens_chat_conversation_delete_confirm.tr()),
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
      await ref
          .read(conversationsListProvider.notifier)
          .deleteConversation(widget.chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: context.auraTheme.spacing.sm,
        vertical: context.auraTheme.spacing.xs,
      ),
      child: AuraPopupMenu(
        controller: _menuController,
        items: [
          AuraPopupMenuItem(
            title: TextLocale(LocaleKeys.common_delete),
            leading: const Icon(Icons.delete_outline),
            onTap: () => _handleDelete(context),
          ),
        ],
        child: AuraTile(
          variant:
              widget.isActive ? AuraTileVariant.surface : AuraTileVariant.ghost,
          size: AuraTileSize.small,
          onTap: () => ConversationRoute(chatId: widget.chat.id).go(context),
          leading: AuraIcon(
            Icons.chat_bubble_outline,
            size: AuraIconSize.small,
            color: widget.isActive
                ? AuraColorVariant.primary
                : AuraColorVariant.onSurfaceVariant,
          ),
          trailing: AuraIconButton(
            icon: Icons.more_vert,
            variant: AuraIconButtonVariant.ghost,
            size: AuraIconSize.small,
            tooltip: LocaleKeys.chats_screens_chat_conversation_delete_tooltip.tr(),
            onPressed: () => _menuController.toggle(),
          ),
          child: AuraText(
            style: AuraTextStyle.bodySmall,
            color: widget.isActive ? AuraColorVariant.primary : null,
            child: Text(
              widget.chat.title,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Add required imports**

At the top of the file, add `easy_localization` import:

```dart
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/providers/router_providers.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';  // ADD THIS
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
```

**Step 3: Run analyze to verify**

Run:
```bash
cd apps/auravibes_app && fvm flutter analyze lib/features/chats/widgets/sidebar_conversations_widget.dart
```

Expected: No issues found.

**Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/widgets/sidebar_conversations_widget.dart
git commit -m "feat(chats): add delete menu to sidebar conversation tiles"
```

---

## Task 3: Add Delete to Chat List Tile

**Files:**
- Modify: `apps/auravibes_app/lib/features/chats/widgets/chat_list_widget.dart`

**Step 1: Add required imports**

At the top of the file (after line 9), add:

```dart
import 'package:auravibes_app/domain/entities/conversation.dart';
import 'package:auravibes_app/features/chats/providers/conversation_providers.dart';
import 'package:auravibes_app/features/models/providers/list_chat_models_providers.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';  // ADD THIS
import 'package:auravibes_app/presentation/shared/formatters/relative_time_formatter.dart';
import 'package:auravibes_app/router/app_router.dart';
import 'package:auravibes_app/widgets/text_locale.dart';  // ADD THIS
import 'package:auravibes_ui/ui.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';  // ADD THIS
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
```

**Step 2: Convert `_ChatTile` to ConsumerStatefulWidget**

Replace the `_ChatTile` class (lines 72-147) with:

```dart
class _ChatTile extends ConsumerStatefulWidget {
  const _ChatTile({required this.chat});

  final ConversationEntity chat;

  @override
  ConsumerState<_ChatTile> createState() => _ChatTileState();
}

class _ChatTileState extends ConsumerState<_ChatTile> {
  final _menuController = AuraPopupMenuController();

  @override
  void dispose() {
    _menuController.close();
    super.dispose();
  }

  Future<void> _handleDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(LocaleKeys.chats_screens_chat_conversation_delete_title.tr()),
        content: Text(LocaleKeys.chats_screens_chat_conversation_delete_confirm.tr()),
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
      await ref
          .read(conversationsListProvider.notifier)
          .deleteConversation(widget.chat.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final modelDisplayName = ref.watch(
      listCredentialsCredentialsProvider.select(
        (cms) => cms.value
            ?.firstWhereOrNull((cm) => cm.credentialsModel.id == widget.chat.modelId)
            ?.credentialsModel
            .modelId,
      ),
    );
    return AuraPopupMenu(
      controller: _menuController,
      items: [
        AuraPopupMenuItem(
          title: TextLocale(LocaleKeys.common_delete),
          leading: const Icon(Icons.delete_outline),
          onTap: () => _handleDelete(context),
        ),
      ],
      child: AuraCard(
        onTap: () {
          ConversationRoute(chatId: widget.chat.id).go(context);
        },
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (widget.chat.isPinned) ...[
                        const AuraIcon(
                          Icons.push_pin_outlined,
                          size: AuraIconSize.small,
                          color: AuraColorVariant.warning,
                        ),
                        const SizedBox(width: 8),
                      ],
                      Expanded(
                        child: AuraText(
                          style: AuraTextStyle.heading6,
                          child: Text(
                            widget.chat.title,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  AuraText(
                    style: AuraTextStyle.bodySmall,
                    color: AuraColorVariant.onSurfaceVariant,
                    child: Text(
                      formatRelativeTime(widget.chat.updatedAt),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (modelDisplayName != null) ...[
              const SizedBox(width: 8),
              AuraBadge.text(
                variant: AuraBadgeVariant.info,
                child: Text(modelDisplayName),
              ),
            ],
            const SizedBox(width: 8),
            AuraIconButton(
              icon: Icons.more_vert,
              variant: AuraIconButtonVariant.ghost,
              size: AuraIconSize.small,
              tooltip: LocaleKeys.chats_screens_chat_conversation_delete_tooltip.tr(),
              onPressed: () => _menuController.toggle(),
            ),
          ],
        ),
      ),
    );
  }
}
```

**Step 3: Run analyze to verify**

Run:
```bash
cd apps/auravibes_app && fvm flutter analyze lib/features/chats/widgets/chat_list_widget.dart
```

Expected: No issues found.

**Step 4: Commit**

```bash
git add apps/auravibes_app/lib/features/chats/widgets/chat_list_widget.dart
git commit -m "feat(chats): add delete menu to chat list tiles"
```

---

## Task 4: Manual Testing & Verification

**Step 1: Run the app**

```bash
cd apps/auravibes_app && fvm flutter run
```

**Step 2: Verify delete functionality in sidebar**

1. Open the app sidebar
2. Find a conversation in "Recent Chats"
3. Tap the ⋮ icon on a conversation tile
4. Verify popup menu appears with "Delete" option
5. Tap "Delete"
6. Verify confirmation dialog appears with "Cancel" and "Delete" buttons
7. Tap "Cancel" → conversation should NOT be deleted
8. Repeat steps 3-5, then tap "Delete" → conversation should be removed

**Step 3: Verify delete functionality in chat list screen**

1. Navigate to Chats screen (full list)
2. Repeat verification steps from Step 2 for the chat tiles

**Step 4: Verify locale switching**

1. Change app language to Spanish
2. Verify all delete UI text appears in Spanish

**Step 5: Final commit (if any fixes needed)**

```bash
git add -A
git commit -m "fix(chats): address delete conversation issues"
```

---

## Summary

| Task | Description | Files Modified |
|------|-------------|----------------|
| 1 | Add locale keys | `en.json`, `es.json`, `locale_keys.dart` |
| 2 | Sidebar delete | `sidebar_conversations_widget.dart` |
| 3 | Chat list delete | `chat_list_widget.dart` |
| 4 | Testing | N/A |

**Total: 4 files modified, 0 files created**
