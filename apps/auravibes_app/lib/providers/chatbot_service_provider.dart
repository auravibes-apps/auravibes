// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/services/chatbot_service/chatbot_service.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chatbot_service_provider.g.dart';

/// Provider that creates a ChatbotService without tools.
/// (for title generation, etc.)
@Riverpod(keepAlive: true)
ChatbotService chatbotService(
  Ref ref,
) {
  return ChatbotService(
    encryptionService: ref.watch(encryptionServiceProvider),
  );
}
