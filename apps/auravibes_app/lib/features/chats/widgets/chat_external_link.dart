import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/confirmed_external_link.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

Future<void> openChatExternalLink(BuildContext context, String url) =>
    ConfirmedExternalLink.open(
      context: context,
      url: url,
      confirm: (uri) => _confirmChatExternalLink(context, uri),
      onLaunchFailure: () => _showChatExternalLinkError(context),
    );

Future<bool?> _confirmChatExternalLink(BuildContext context, Uri uri) =>
    AuraDialogs.confirm(
      context: context,
      title: Text(
        LocaleKeys.chats_screens_chat_conversation_external_link_title.tr(),
      ),
      message: AuraSelectableText(
        LocaleKeys.chats_screens_chat_conversation_external_link_message.tr(
          namedArgs: {'host': uri.host, 'url': uri.toString()},
        ),
      ),
      actions: .new(
        confirmLabel: Text(
          LocaleKeys.chats_screens_chat_conversation_external_link_open.tr(),
        ),
        cancelLabel: Text(LocaleKeys.common_cancel.tr()),
      ),
    );

void _showChatExternalLinkError(BuildContext context) {
  unawaited(AuraHaptics.error());
  final _ = ScaffoldMessenger.of(context).showSnackBar(
    const .new(
      content: TextLocale(
        LocaleKeys.models_screens_add_provider_device_code_open_link_failed,
      ),
    ),
  );
}
