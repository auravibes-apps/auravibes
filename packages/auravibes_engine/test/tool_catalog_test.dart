import 'package:auravibes_engine/auravibes_engine.dart';
import 'package:test/test.dart';

void main() {
  ToolSpec spec(String name) =>
      ToolSpec(name: name, description: name, inputJsonSchema: const {});

  test('keeps reserved native command names unchanged', () {
    final catalog = buildToolCatalog<String>([
      ToolCatalogCandidate.reserved(
        spec: spec('call_skill_tool'),
        target: 'skill',
      ),
      ToolCatalogCandidate.reserved(spec: spec('run_sub_agent'), target: 'sub'),
    ]);

    expect(catalog.specs.map((value) => value.name), [
      'call_skill_tool',
      'run_sub_agent',
    ]);
    expect(catalog.resolve('call_skill_tool'), 'skill');
  });

  test('gives repeated user tools distinct stable names', () {
    final catalog = buildToolCatalog<String>([
      ToolCatalogCandidate.external(
        spec: spec('calculator'),
        target: 'first',
        sourceId: 'workspace-tool-1',
      ),
      ToolCatalogCandidate.external(
        spec: spec('calculator'),
        target: 'second',
        sourceId: 'workspace-tool-2',
      ),
    ]);

    final names = catalog.specs.map((value) => value.name).toList();
    expect(names.toSet(), hasLength(2));
    expect(
      names,
      everyElement(matches(RegExp(r'^calculator_[A-Za-z0-9_-]{10}$'))),
    );
    expect(catalog.resolve(names[0]), 'first');
    expect(catalog.resolve(names[1]), 'second');
  });

  test('separates same MCP tool name by server identity', () {
    final catalog = buildToolCatalog<String>([
      ToolCatalogCandidate.external(
        spec: spec('mcp_search'),
        target: 'github',
        sourceId: 'github-server/search',
      ),
      ToolCatalogCandidate.external(
        spec: spec('mcp_search'),
        target: 'linear',
        sourceId: 'linear-server/search',
      ),
    ]);

    expect(catalog.specs.map((value) => value.name).toSet(), hasLength(2));
  });

  test('separates normalized tool names from one source', () {
    final catalog = buildToolCatalog<String>([
      ToolCatalogCandidate.external(
        spec: spec('weather.current'),
        target: 'dot',
        sourceId: 'shared-source',
      ),
      ToolCatalogCandidate.external(
        spec: spec('weather/current'),
        target: 'slash',
        sourceId: 'shared-source',
      ),
    ]);

    final names = catalog.specs.map((value) => value.name).toList();
    expect(names.toSet(), hasLength(2));
    expect(catalog.resolve(names[0]), 'dot');
    expect(catalog.resolve(names[1]), 'slash');
  });

  test('rejects duplicate reserved names', () {
    expect(
      () => buildToolCatalog<String>([
        ToolCatalogCandidate.reserved(
          spec: spec('call_skill_tool'),
          target: 'one',
        ),
        ToolCatalogCandidate.reserved(
          spec: spec('call_skill_tool'),
          target: 'two',
        ),
      ]),
      throwsStateError,
    );
  });
}
