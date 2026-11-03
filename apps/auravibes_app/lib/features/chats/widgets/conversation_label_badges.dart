import 'package:auravibes_app/domain/entities/conversation_label_entity.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart' show ValueKey;
import 'package:flutter/widgets.dart';

class ConversationLabelBadges({
  super.key,
  required final List<ConversationLabelEntity> labels,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (labels.isEmpty) return const SizedBox.shrink();

    final labelNames = labels.map((label) => label.name).join(', ');
    final semanticsLabel =
        '${LocaleKeys.chats_screens_conversation_labels_label_semantics.tr(context: context)}: '
        '$labelNames';

    return Semantics(
      key: const ValueKey('conversation-labels-semantics'),
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Wrap(
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
        ),
      ),
    );
  }
}
