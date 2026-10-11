import 'dart:async' show unawaited;

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

class const MarkdownPreview({required final String text, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => GptMarkdown(
    text,
    onLinkTap: (url, _) => unawaited(_openExternalLink(context, url)),
  );
}

Future<void> _openExternalLink(BuildContext context, String url) async {
  final uri = Uri.tryParse(url);
  final scheme = uri?.scheme.toLowerCase();
  if (uri == null ||
      !uri.isAbsolute ||
      !uri.hasAuthority ||
      (scheme != 'http' && scheme != 'https') ||
      uri.host.isEmpty ||
      uri.userInfo.isNotEmpty) {
    return;
  }

  final confirmed = await AuraDialogs.confirm(
    context: context,
    title: Text(LocaleKeys.markdown_editor_external_link_title.tr()),
    message: AuraSelectableText(
      LocaleKeys.markdown_editor_external_link_message.tr(
        namedArgs: {'host': uri.host, 'url': uri.toString()},
      ),
    ),
    actions: .new(
      confirmLabel: Text(LocaleKeys.markdown_editor_external_link_open.tr()),
      cancelLabel: Text(LocaleKeys.common_cancel.tr()),
    ),
  );
  if (confirmed != true || !context.mounted) return;

  try {
    await OpenSystemBrowser.call(uri);
  } on Object {
    if (!context.mounted) return;
    unawaited(AuraHaptics.error());
    const errorMessage = TextLocale(
      LocaleKeys.markdown_editor_external_link_error,
    );
    final _ = ScaffoldMessenger.of(context)
        .showSnackBar(const .new(content: errorMessage));
  }
}
