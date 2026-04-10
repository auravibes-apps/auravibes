import 'package:auravibes_app/core/exceptions/conversation_exceptions.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_selection_provider.g.dart';

@Riverpod(dependencies: [])
String conversationSelected(Ref ref) =>
    throw const NoConversationSelectedException();
