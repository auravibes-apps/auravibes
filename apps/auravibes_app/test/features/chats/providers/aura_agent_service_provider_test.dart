import 'package:auravibes_app/features/chats/agent_adapters/app_agent_service.dart';
import 'package:auravibes_app/features/chats/providers/aura_agent_service_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares scoped agent data dependencies', () {
    expect(
      auraAgentServiceProvider.dependencies,
      containsAll([appAgentDataProvider, appAgentModelProvider]),
    );
  });
}
