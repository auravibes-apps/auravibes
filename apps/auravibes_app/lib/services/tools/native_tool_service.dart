import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/native_tools/url_tool.dart';
import 'package:collection/collection.dart';

class NativeToolService {
  static final List<NativeToolEntity<Object, Object>> availableTools = [
    UrlTool(),
  ];

  static List<NativeToolType> getTypes() =>
      availableTools.map((e) => e.type).toList();

  static NativeToolEntity<Object, Object>? getTool(
    NativeToolType toolType,
  ) {
    return availableTools.firstWhereOrNull(
      (element) => element.type == toolType,
    );
  }

  static bool hasTypeString(String type) =>
      availableTools.any((tool) => tool.type.value == type);
}
