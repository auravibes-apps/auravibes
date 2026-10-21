import 'package:auravibes_app/utils/open_system_browser.dart';
import 'package:flutter/widgets.dart';

abstract final class ConfirmedExternalLink {
  static Future<void> open({
    required BuildContext context,
    required String url,
    required Future<bool?> Function(Uri uri) confirm,
    required VoidCallback onLaunchFailure,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !_isSafeExternalUri(uri)) return;

    final confirmed = await confirm(uri);
    if (confirmed != true || !context.mounted) return;

    try {
      await OpenSystemBrowser.call(uri);
    } on Object {
      if (!context.mounted) return;
      onLaunchFailure();
    }
  }

  static bool _isSafeExternalUri(Uri uri) =>
      uri.isAbsolute &&
      uri.hasAuthority &&
      const {'http', 'https'}.contains(uri.scheme.toLowerCase()) &&
      uri.host.isNotEmpty &&
      uri.userInfo.isEmpty;
}
