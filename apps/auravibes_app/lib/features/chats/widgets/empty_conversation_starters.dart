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
  final String? selectedText,
  final String keyPrefix = 'chat_empty_starter',
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => _EmptyConversationStarterViewport(
      minHeight: constraints.maxHeight,
      onSelect: onSelect,
      selectedText: selectedText,
      keyPrefix: keyPrefix,
    ),
  );
}

class const _EmptyConversationStarterViewport({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
  final String? selectedText,
  required final String keyPrefix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(24),
    primary: false,
    child: _EmptyConversationStarterFrame(
      minHeight: minHeight,
      onSelect: onSelect,
      selectedText: selectedText,
      keyPrefix: keyPrefix,
    ),
  );
}

class const _EmptyConversationStarterFrame({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
  final String? selectedText,
  required final String keyPrefix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(minHeight: minHeight),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _EmptyConversationStarterContent(
          onSelect: onSelect,
          selectedText: selectedText,
          keyPrefix: keyPrefix,
        ),
      ),
    ),
  );
}

class const _EmptyConversationStarterContent({
  required final ValueChanged<ChatDraft> onSelect,
  final String? selectedText,
  required final String keyPrefix,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      const _EmptyConversationStarterHeading(),
      const AuraSizedBox(height: .xs),
      EmptyConversationStarterChoices(
        onSelect: onSelect,
        selectedText: selectedText,
        keyPrefix: keyPrefix,
      ),
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

class const EmptyConversationStarterChoices({
  required final ValueChanged<ChatDraft> onSelect,
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
      ),
      selected: selected,
    );
  }
}
