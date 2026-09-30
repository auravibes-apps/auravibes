import 'package:auravibes_app/i18n/locale_keys.dart';

class const McpCatalogSignInRequired() implements Exception {
  String get localizationKey => LocaleKeys.mcp_catalog_sign_in_required;

  @override
  String toString() => localizationKey;
}
