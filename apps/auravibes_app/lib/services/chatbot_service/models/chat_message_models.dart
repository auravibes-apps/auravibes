import 'package:freezed_annotation/freezed_annotation.dart';

part 'chat_message_models.freezed.dart';

@freezed
abstract class ChatbotToolCall with _$ChatbotToolCall {
  const factory ChatbotToolCall({
    required String id,
    required String name,
    required Map<String, dynamic> arguments,
    required String argumentsRaw,
    String? responseRaw,
  }) = _ChatbotToolCall;
}
