import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

const _planDayKey = 'chats_screens.chat_conversation.empty_starters.plan_day';
const _shoppingListKey =
    'chats_screens.chat_conversation.empty_starters.shopping_list';
const _personalMessageKey =
    'chats_screens.chat_conversation.empty_starters.personal_message';

class const EmptyConversationStarterChoices({
  required final ValueChanged<ChatDraft> onSelect,
  final bool disabled = false,
  final String? selectedText,
  final String keyPrefix = 'chat_empty_starter',
  super.key,
}) extends StatelessWidget {
  static const List<({String id, String localizationKey})> _starters = [
    (id: 'plan_day', localizationKey: _planDayKey),
    (id: 'shopping_list', localizationKey: _shoppingListKey),
    (id: 'personal_message', localizationKey: _personalMessageKey),
  ];

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      for (final starter in _starters)
        _EmptyConversationStarterButton(
          localizationKey: starter.localizationKey,
          onSelect: onSelect,
          disabled: disabled,
          selectedText: selectedText,
          key: ValueKey('${keyPrefix}_${starter.id}'),
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
  required final bool disabled,
  final String? selectedText,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = localizationKey.tr(context: context);
    final selected = text == selectedText;

    return Semantics(
      child: AuraButton(
        onPressed: () => onSelect(.new(text: text)),
        child: Text(text),
        variant: selected ? .secondary : .outlined,
        isFullWidth: true,
        disabled: disabled,
      ),
      selected: selected,
    );
  }
}
