import 'package:auravibes_app/i18n/locale_keys.dart';

class const McpLegacySseUnavailableException() implements Exception {
  String get localizationKey => LocaleKeys.mcp_modal_legacy_sse_unavailable;

  @override
  String toString() => localizationKey;
}
