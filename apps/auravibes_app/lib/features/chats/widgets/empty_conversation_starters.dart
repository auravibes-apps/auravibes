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
    builder: (context, constraints) => _EmptyConversationStarterViewport(
      minHeight: constraints.maxHeight,
      onSelect: onSelect,
    ),
  );
}

class const _EmptyConversationStarterViewport({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(24),
    primary: false,
    child: _EmptyConversationStarterFrame(
      minHeight: minHeight,
      onSelect: onSelect,
    ),
  );
}

class const _EmptyConversationStarterFrame({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(minHeight: minHeight),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _EmptyConversationStarterContent(onSelect: onSelect),
      ),
    ),
  );
}

class const _EmptyConversationStarterContent({
  required final ValueChanged<ChatDraft> onSelect,
}) extends StatelessWidget {
  static const List<({String id, String localizationKey})> _starters = [
    (id: 'chat_empty_starter_plan_day', localizationKey: _planDayKey),
    (id: 'chat_empty_starter_shopping_list', localizationKey: _shoppingListKey),
    (
      id: 'chat_empty_starter_personal_message',
      localizationKey: _personalMessageKey,
    ),
  ];

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _EmptyConversationStarterHeading(),
      const AuraSizedBox(height: .xs),
      _EmptyConversationStarterChoices(starters: _starters, onSelect: onSelect),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
    mainAxisSize: .min,
  );
}

class const _EmptyConversationStarterHeading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const AuraColumn(
    children: [
      AuraText(child: TextLocale(_titleKey), style: .heading5),
      AuraText(child: TextLocale(_helperKey), style: .bodySmall),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
    mainAxisSize: .min,
  );
}

class const _EmptyConversationStarterChoices({
  required final List<({String id, String localizationKey})> starters,
  required final ValueChanged<ChatDraft> onSelect,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final starter in starters)
        _EmptyConversationStarterButton(
          localizationKey: starter.localizationKey,
          onSelect: onSelect,
          key: ValueKey(starter.id),
        ),
    ],
    spacing: .sm,
    crossAxisAlignment: .stretch,
    mainAxisSize: .min,
  );
}

class const _EmptyConversationStarterButton({
  required final String localizationKey,
  required final ValueChanged<ChatDraft> onSelect,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = localizationKey.tr(context: context);

    return AuraButton(
      onPressed: () => onSelect(.new(text: text)),
      child: Text(text),
      variant: .outlined,
      isFullWidth: true,
    );
  }
}
