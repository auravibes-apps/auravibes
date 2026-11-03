import 'package:auravibes_app/data/repositories/conversation_labels_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/riverpod.dart';

final conversationLabelsRepositoryProvider =
    Provider<ConversationLabelsRepository>(
      (ref) => ConversationLabelsRepository(ref.watch(appDatabaseProvider)),
    );
