import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/mcp_elicitation_url_opener.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'open_mcp_elicitation_url_usecase.g.dart';

@riverpod
OpenMcpElicitationUrlUsecase openMcpElicitationUrlUsecase(Ref ref) =>
    OpenMcpElicitationUrlUsecase(
      urlOpener: ref.watch(mcpElicitationUrlOpenerProvider),
    );

class const OpenMcpElicitationUrlUsecase({
  required final McpElicitationUrlOpener urlOpener,
}) {
  Future<void> call(Uri url) async {
    try {
      await urlOpener.open(url);
    } on Exception catch (error, stackTrace) {
      Error.throwWithStackTrace(
        McpElicitationUrlOpenException(cause: error),
        stackTrace,
      );
    }
  }
}

final class const McpElicitationUrlOpenException({
  required final Exception cause,
}) implements Exception {
  String get localizationKey => LocaleKeys.mcp_elicitation_open_error;

  @override
  String toString() => localizationKey;
}
