import 'package:auravibes_agent/auravibes_agent.dart' as agent;
import 'package:auravibes_app/features/skills/usecases/list_available_skills_usecase.dart';
import 'package:auravibes_app/services/chatbot_service/chat_result.dart';
import 'package:riverpod/riverpod.dart';

class BuildSkillContextMessagesService {
  const BuildSkillContextMessagesService(this._listAvailableSkillsUsecase);

  static const _builder = agent.BuildSkillContextMessages();

  final ListAvailableSkillsUsecase _listAvailableSkillsUsecase;

  Future<List<ChatMessage>> call({
    required String conversationId,
    required String workspaceId,
  }) async {
    final loadedSkills = await _listAvailableSkillsUsecase.call(
      conversationId: conversationId,
      workspaceId: workspaceId,
      filter: SkillLoadFilter.loaded,
    );

    final agentMessages = _builder.call([
      for (final skill in loadedSkills)
        agent.AgentSkill(title: skill.title, content: skill.content),
    ]);

    return [
      for (final message in agentMessages)
        ChatMessage(
          role: switch (message.role) {
            agent.AgentChatMessageRole.system => ChatMessageRole.system,
            agent.AgentChatMessageRole.user => ChatMessageRole.user,
            agent.AgentChatMessageRole.model => ChatMessageRole.model,
            agent.AgentChatMessageRole.tool => ChatMessageRole.tool,
          },
          content: message.content,
          metadata: Map<String, Object?>.of(message.metadata),
        ),
    ];
  }
}

final buildSkillContextMessagesServiceProvider =
    Provider<BuildSkillContextMessagesService>((ref) {
      return BuildSkillContextMessagesService(
        ref.watch(listAvailableSkillsUsecaseProvider),
      );
    });
