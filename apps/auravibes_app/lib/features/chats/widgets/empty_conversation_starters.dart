import 'package:auravibes_app/features/chats/models/chat_draft.dart';
import 'package:auravibes_app/features/chats/widgets/empty_conversation_starter_choices.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';

typedef EmptyConversationStarterRequest = ({
  bool enabled,
  bool hasDraftToLoad,
  bool composerHasDraft,
  ValueChanged<ChatDraft> onSelect,
});

const _titleKey = 'chats_screens.chat_conversation.empty_starters.title';
const _helperKey = 'chats_screens.chat_conversation.empty_starters.helper';

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
      keyPrefix: keyPrefix,
      selectedText: selectedText,
    ),
  );
}

class const _EmptyConversationStarterViewport({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
  required final String keyPrefix,
  final String? selectedText,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    padding: const .all(24),
    primary: false,
    child: _EmptyConversationStarterFrame(
      minHeight: minHeight,
      onSelect: onSelect,
      keyPrefix: keyPrefix,
      selectedText: selectedText,
    ),
  );
}

class const _EmptyConversationStarterFrame({
  required final double minHeight,
  required final ValueChanged<ChatDraft> onSelect,
  required final String keyPrefix,
  final String? selectedText,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(minHeight: minHeight),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: _EmptyConversationStarterContent(
          onSelect: onSelect,
          keyPrefix: keyPrefix,
          selectedText: selectedText,
        ),
      ),
    ),
  );
}

class const _EmptyConversationStarterContent({
  required final ValueChanged<ChatDraft> onSelect,
  required final String keyPrefix,
  final String? selectedText,
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
