import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

typedef EmptyConversationStarterRequest = ({
  bool enabled,
  bool hasDraftToLoad,
  bool composerHasDraft,
  ValueChanged<ChatDraft> onSelect,
});

const _titleKey = 'chats_screens.chat_conversation.empty_starters.title';
const _helperKey = 'chats_screens.chat_conversation.empty_starters.helper';
const _planDayKey = 'chats_screens.chat_conversation.empty_starters.plan_day';
const _shoppingListKey =
    'chats_screens.chat_conversation.empty_starters.shopping_list';
const _personalMessageKey =
    'chats_screens.chat_conversation.empty_starters.personal_message';

class const EmptyConversationStarters({
  required final ValueChanged<ChatDraft> onSelect,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => SingleChildScrollView(
      padding: const .all(24),
      child: ConstrainedBox(
        constraints: .new(minHeight: constraints.maxHeight),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: _EmptyConversationStarterContent(onSelect: onSelect),
          ),
        ),
      ),
    ),
  );
}

class const _EmptyConversationStarterContent({
  required final ValueChanged<ChatDraft> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    crossAxisAlignment: .stretch,
    mainAxisSize: .min,
    spacing: .sm,
    children: [
      const AuraText(child: TextLocale(_titleKey), style: .heading5),
      const AuraText(child: TextLocale(_helperKey), style: .bodySmall),
      const AuraSizedBox(height: .xs),
      _EmptyConversationStarterButton(
        key: const ValueKey('chat_empty_starter_plan_day'),
        onPressed: () =>
            onSelect(ChatDraft(text: _planDayKey.tr(context: context))),
        child: const TextLocale(_planDayKey),
      ),
      _EmptyConversationStarterButton(
        key: const ValueKey('chat_empty_starter_shopping_list'),
        onPressed: () =>
            onSelect(ChatDraft(text: _shoppingListKey.tr(context: context))),
        child: const TextLocale(_shoppingListKey),
      ),
      _EmptyConversationStarterButton(
        key: const ValueKey('chat_empty_starter_personal_message'),
        onPressed: () =>
            onSelect(ChatDraft(text: _personalMessageKey.tr(context: context))),
        child: const TextLocale(_personalMessageKey),
      ),
    ],
  );
}

class const _EmptyConversationStarterButton({
  required final VoidCallback onPressed,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraButton(
    onPressed: onPressed,
    child: child,
    variant: .outlined,
    isFullWidth: true,
  );
}
