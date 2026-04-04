usecases are for business logic and coordinate actions between providers, notifiers, and repositories.


They should not contain any UI code or directly manipulate state.
Instead, they should focus on performing a specific task or action, such as sending a message, fetching data, or processing user input. Usecases can be called from the UI layer (e.g., from a button press) and can interact with repositories to fetch or update data, and with notifiers to update the UI state indirectly.

### Where to Find Usecases
Usecases are typically found in:
`apps/<app_name>/lib/features/<feature_name>/usecases/` directory. Each usecase should be in its own file, and the file name should reflect the action it performs (e.g., `send_new_message_usecase.dart` with class name: `SendNewMessageUsecase`).

using DI to inject dependencies into the usecase, such as repositories and notifiers, allows for better separation of concerns and makes the usecase easier to test. The usecase should not directly create instances of its dependencies but should receive them through its constructor, often using a provider to manage the dependencies.

# Cascade pattern
Usecases can call other usecases to perform complex actions. For example, a `SendNewMessageUsecase` might call a `GenerateTitleUsecase` to create a title for a conversation after sending a message. This allows for better code reuse and separation of concerns, as each usecase is responsible for a specific piece of functionality.

and not create circular dependencies, even deeply nested ones. For example, if `SendNewMessageUsecase` calls `GenerateTitleUsecase`, then `GenerateTitleUsecase` should not call `SendNewMessageUsecase` or any usecase that eventually calls `SendNewMessageUsecase`. This ensures that the flow of actions is clear and prevents infinite loops in the logic.

if this circular dependency happens, it indicates that the usecases are too tightly coupled and may need to be refactored to better separate concerns. Each usecase should have a clear responsibility and should not depend on the internal workings of another usecase.

a usecase cannot be a single dependency call, as that would not justify the existence of the usecase layer. Instead, a usecase should coordinate multiple actions, such as calling multiple repositories, performing some business logic, and then updating the state through notifiers. If a usecase is just a thin wrapper around a single repository call, it may be an indication that the usecase layer is not being used effectively and that the logic could be moved directly into the repository or notifier instead.

create usecase only when is reusable, representing minninfull business action. either called from other usecases or UI actions.

optimise uasecases for:
- reusability
- testability
- clear business boundaries
- fewer, stronger usecases
- not many micro usecases

# Example of a Usecase
```dart
import 'package:auravibes_app/domain/repositories/chat_models_repository.dart';
import 'package:auravibes_app/domain/repositories/conversation_repository.dart';
import 'package:auravibes_app/features/chats/providers/conversation_repository_provider.dart';
import 'package:auravibes_app/features/chats/screens/usecases/generate_title_usecase.dart';
import 'package:auravibes_app/features/chats/screens/usecases/send_message_usecase  .dart';
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
   Future<void> call({
     required String workspaceId,
     required String conversationId,
     required String messageContent,
   }) async {
     // Implementation of sending a new message and generating a title if needed
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