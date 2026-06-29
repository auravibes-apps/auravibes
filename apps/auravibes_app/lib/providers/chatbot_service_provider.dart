// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/features/service_connections/providers/service_connection_repository_provider.dart';
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/oauth_credential_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chatbot_service_provider.g.dart';

/// Provider that creates a ChatbotService without tools.
/// (for title generation, etc.)
@Riverpod(keepAlive: true)
ChatbotService chatbotService(
  Ref ref,
) {
  return ChatbotService(
    serviceConnectionRepository: ref.watch(serviceConnectionRepositoryProvider),
    oauthCredentialService: ref.watch(oauthCredentialServiceProvider),
  );
}
