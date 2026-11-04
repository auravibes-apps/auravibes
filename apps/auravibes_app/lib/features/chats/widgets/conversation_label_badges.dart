import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class const ConversationLabelBadges({
  required final List<ConversationLabelEntity> labels,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => _ConversationLabelBadgeContent(
    labels: labels,
    semanticLabel: LocaleKeys
        .chats_screens_conversation_labels_label_semantics
        .tr(context: context),
  );
}

class const _ConversationLabelBadgeContent({
  required final List<ConversationLabelEntity> labels,
  required final String semanticLabel,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    return Semantics(
      key: const ValueKey('conversation-labels-semantics'),
      child: ExcludeSemantics(child: _ConversationLabelBadgeWrap(labels: labels)),
      container: true,
      label: '$semanticLabel: ${_conversationLabelNames(labels)}',
    );
  }
}

class const _ConversationLabelBadgeWrap({
  required final List<ConversationLabelEntity> labels,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 4,
    children: [
      for (final label in labels)
        AuraBadge.text(
          child: Text(label.name),
          key: ValueKey('conversation-label-${label.id}'),
          variant: .neutral,
          size: .small,
        ),
    ],
  );
}

String _conversationLabelNames(List<ConversationLabelEntity> labels) =>
    labels.map((label) => label.name).join(', ');
