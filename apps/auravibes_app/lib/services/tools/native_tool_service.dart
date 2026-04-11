import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/native_tools/url_tool.dart';
import 'package:collection/collection.dart';

class NativeToolService {
  static final List<NativeToolEntity<Object, Object>> _availableTools = [
    UrlTool(),
  ];

  static List<NativeToolType> getTypes() =>
      _availableTools.map((e) => e.type).toList();

  static NativeToolEntity<Object, Object>? getTool(
    NativeToolType toolType,
  ) {
    return _availableTools.firstWhereOrNull(
      (element) => element.type == toolType,
    );
  }

  static bool hasTypeString(String type) =>
      _availableTools.any((tool) => tool.type.value == type);
}
