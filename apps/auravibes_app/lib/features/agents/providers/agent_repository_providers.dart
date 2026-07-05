import 'package:auravibes_app/data/repositories/agent_tools_repository.dart';
import 'package:auravibes_app/data/repositories/agents_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'agent_repository_providers.g.dart';

@Riverpod(keepAlive: true)
AgentsRepository agentsRepository(Ref ref) {
  return AgentsRepository(ref.watch(appDatabaseProvider));
}

@Riverpod(keepAlive: true)
AgentToolsRepository agentToolsRepository(Ref ref) {
  return AgentToolsRepository(ref.watch(appDatabaseProvider));
}
