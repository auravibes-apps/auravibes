import 'dart:async' show unawaited;

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/confirmed_external_link.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const MarkdownPreview({required final String text, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      GptMarkdown(text, onLinkTap: (url, _) => _onLinkTap(context, url));

  static void _onLinkTap(BuildContext context, String url) => unawaited(
    ConfirmedExternalLink.open(
      context: context,
      url: url,
      confirm: (uri) => _confirmExternalLink(context, uri),
      onLaunchFailure: () => _showExternalLinkError(context),
    ),
  );
}

Future<bool?> _confirmExternalLink(BuildContext context, Uri uri) =>
    AuraDialogs.confirm(
      context: context,
      title: Text(LocaleKeys.markdown_editor_external_link_title.tr()),
      message: AuraSelectableText(_localizedExternalLinkMessage(uri)),
      actions: _externalLinkActions(),
    );

String _localizedExternalLinkMessage(Uri uri) => LocaleKeys
    .markdown_editor_external_link_message
    .tr(namedArgs: {'host': uri.host, 'url': uri.toString()});

AuraConfirmDialogActions _externalLinkActions() => .new(
  confirmLabel: Text(LocaleKeys.markdown_editor_external_link_open.tr()),
  cancelLabel: Text(LocaleKeys.common_cancel.tr()),
);

void _showExternalLinkError(BuildContext context) {
  unawaited(AuraHaptics.error());
  const errorMessage = TextLocale(
    LocaleKeys.markdown_editor_external_link_error,
  );
  final _ = ScaffoldMessenger.of(context)
      .showSnackBar(const .new(content: errorMessage));
}
