import 'package:auravibes_engine/auravibes_engine.dart';
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
      expect(tool?.mcpSlug, 'calc');
      expect(tool?.toolIdentifier, 'sum');
      expect(tool?.fullName, 'mcp_server-1_calc_sum');
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
      expect(builtIn?.fullName, 'built_in_calc_calculator');
      expect(native?.fullName, 'native_url_url');
    });

    test('matches configured and composite names exactly', () {
      expect(resolver.resolve('LOAD_SKILL'), isNull);
      expect(resolver.resolve('Built_in_calc_calculator'), isNull);
      expect(resolver.resolve('skill__User__writer__draft'), isNull);
    });

    test('rejects malformed composite names', () {
      for (final name in [
        '',
        'skill__user__writer',
        'skill__other__writer__draft',
        'skill__user____draft',
        'skill__user__writer__',
        'skill__user__writer__draft__extra',
        'mcp_server_calc',
        'mcp__calc_sum',
        'built_in__calculator',
        'native_url_',
      ]) {
        expect(resolver.resolve(name), isNull, reason: name);
      }
    });
  });

  test('preserves exact lossy skill slug normalization', () {
    expect(generateSkillSlug('  My Café & API  Tool!  '), 'my_caf_api_tool');
    expect(generateSkillSlug('snake_case'), 'snakecase');
    expect(generateSkillSlug('中文'), '');
  });
}
