# Use Cases Pattern

Use cases are for business logic and coordinate actions between repositories, services, and other use cases.

They should not contain any UI code or directly manipulate notifier state. Instead, they should focus on performing a specific task or action, such as sending a message, fetching data, or processing user input. Use cases can be called from the UI layer (e.g., from a button press) or from notifiers. They can interact with repositories and services to fetch or update data, then return results to the caller.

## Runtime Adapter Exception

Use cases may receive plain callback interfaces (runtime adapters) for side effects like streaming state updates, queue management, or title generation. These adapters wrap notifier methods behind simple function signatures so the use case remains decoupled from Riverpod internals. The use case does not import or depend on notifier classes directly — it only depends on the adapter's callback interface.

This pattern is acceptable because the adapter is a plain Dart class with no Riverpod dependency, keeping the use case testable and framework-agnostic.

## Where to Find Use Cases

Use cases are typically found in:
`apps/<app_name>/lib/features/<feature_name>/usecases/` directory. Each use case should be in its own file, and the file name should reflect the action it performs (e.g., `send_new_message_usecase.dart` with class name: `SendNewMessageUsecase`).

Using DI to inject dependencies into the use case, such as repositories and services, allows for better separation of concerns and makes the use case easier to test. The use case should not directly create instances of its dependencies but should receive them through its constructor, often using a provider to manage the dependencies.

## Cascade Pattern

Use cases can call other use cases to perform complex actions. For example, a `SendNewMessageUsecase` might call a `GenerateTitleUsecase` to create a title for a conversation after sending a message. This allows for better code reuse and separation of concerns, as each use case is responsible for a specific piece of functionality.

Do not create circular dependencies, even deeply nested ones. For example, if `SendNewMessageUsecase` calls `GenerateTitleUsecase`, then `GenerateTitleUsecase` should not call `SendNewMessageUsecase` or any use case that eventually calls `SendNewMessageUsecase`. This ensures that the flow of actions is clear and prevents infinite loops in the logic.

If this circular dependency happens, it indicates that the use cases are too tightly coupled and may need to be refactored to better separate concerns. Each use case should have a clear responsibility and should not depend on the internal workings of another use case.

A use case should not be a single dependency call, as that would not justify the existence of the use case layer. Instead, a use case should coordinate multiple actions, such as calling multiple repositories, performing some business logic, and returning the result for the caller to apply to state if needed. If a use case is just a thin wrapper around a single repository call, consider moving that logic directly into the repository or notifier instead.

Create use cases only when reusable, representing meaningful business actions. Either called from other use cases or UI actions.

Optimize use cases for:
- Reusability
- Testability
- Clear business boundaries
- Fewer, stronger use cases
- Not many micro use cases

## Example of a Use Case

```dart
import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/usecases/send_message_usecase.dart';
import 'package:auravibes_app/features/models/providers/model_providers_repository_providers.dart';
import 'package:riverpod/riverpod.dart';

class SendNewMessageUsecase {
  SendNewMessageUsecase({
     required this.conversationRepo,
     required this.sendMessageUsecase,
     required this.credentialsRepository,
     required this.generateTitleUsecase,
   });
 
   final ConversationRepository conversationRepo;
   final SendMessageUsecase sendMessageUsecase;
   final CredentialsModelsRepository credentialsRepository;
   final GenerateTitleUsecase generateTitleUsecase;
   Future<ConversationEntity> call({
      required String workspaceId,
      required String conversationId,
      required String messageContent,
    }) async {
      // Implementation of sending a new message and generating a title if needed
      return newConversation;
    }
}

final sendNewMessageUsecaseProvider = Provider<SendNewMessageUsecase>((ref) {
    final conversationRepo = ref.watch(conversationRepositoryProvider);
    final sendMessageUsecase = ref.watch(sendMessageUsecaseProvider);
    final credentialsRepository = ref.watch(credentialsModelsRepositoryProvider);
    final generateTitleUsecase = ref.watch(generateTitleUsecaseProvider);

    return SendNewMessageUsecase(
      conversationRepo: conversationRepo,
      sendMessageUsecase: sendMessageUsecase,
      credentialsRepository: credentialsRepository,
      generateTitleUsecase: generateTitleUsecase,
    );
});
```
