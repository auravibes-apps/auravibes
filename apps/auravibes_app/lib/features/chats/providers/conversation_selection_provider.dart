// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/core/exceptions/no_conversation_selected_exception.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'conversation_selection_provider.g.dart';

@Riverpod(dependencies: [])
String conversationSelected(Ref _) =>
    throw const NoConversationSelectedException();
