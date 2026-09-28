import 'package:auravibes_app/services/tools/models/resolved_tool_type.dart';
import 'package:auravibes_engine/auravibes_engine.dart';

class const ToolResolverService() {
  ResolvedTool? resolveTool(
    String modelToolName,
    ToolCatalog<ResolvedTool> catalog,
  ) => catalog.resolve(modelToolName);
}
