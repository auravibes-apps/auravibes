import 'package:auravibes_agent/auravibes_agent.dart';
import 'package:test/test.dart';

void main() {
  group('AgentToolNameResolver', () {
    const resolver = AgentToolNameResolver(
      skillControlToolNames: {'load_skill'},
    );

    test('resolves skill control names from configured set', () {
      final tool = resolver.resolve('load_skill');

      expect(tool?.kind, AgentResolvedToolKind.skillControl);
      expect(tool?.toolIdentifier, 'load_skill');
    });

    test('resolves user skill tool names', () {
      final tool = resolver.resolve('skill__user__writer__draft');

      expect(tool?.kind, AgentResolvedToolKind.skillTemplate);
      expect(tool?.skillSlug, 'writer');
      expect(tool?.toolIdentifier, 'draft');
      expect(tool?.fullName, 'skill__user__writer__draft');
    });

    test('resolves app skill tool names', () {
      final tool = resolver.resolve('skill__app__writer__open_url');

      expect(tool?.kind, AgentResolvedToolKind.skillNative);
      expect(tool?.skillSlug, 'writer');
      expect(tool?.toolIdentifier, 'open_url');
      expect(tool?.fullName, 'skill__app__writer__open_url');
    });

    test('resolves MCP tool names', () {
      final tool = resolver.resolve('mcp_server-1_calc_sum');

      expect(tool?.kind, AgentResolvedToolKind.mcp);
      expect(tool?.tableId, 'server-1');
      expect(tool?.mcpServerId, 'server-1');
      expect(tool?.toolIdentifier, 'sum');
    });

    test('resolves built-in and native tool names', () {
      final builtIn = resolver.resolve('built_in_calc_calculator');
      final native = resolver.resolve('native_url_url');

      expect(builtIn?.kind, AgentResolvedToolKind.builtIn);
      expect(builtIn?.tableId, 'calc');
      expect(builtIn?.toolIdentifier, 'calculator');
      expect(native?.kind, AgentResolvedToolKind.native);
      expect(native?.tableId, 'url');
      expect(native?.toolIdentifier, 'url');
    });
  });
}
