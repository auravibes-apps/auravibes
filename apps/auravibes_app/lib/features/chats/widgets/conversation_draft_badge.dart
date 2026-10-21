import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

class const ConversationDraftBadge({
  required final String conversationId,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey('conversation-draft-marker-$conversationId'),
    child: ExcludeSemantics(
      child: AuraBadge.text(
        child: const TextLocale(
          LocaleKeys.chats_screens_chats_list_draft_marker,
        ),
        variant: .info,
      ),
    ),
    container: true,
    label: LocaleKeys.chats_screens_chats_list_draft_marker.tr(),
  );
}
