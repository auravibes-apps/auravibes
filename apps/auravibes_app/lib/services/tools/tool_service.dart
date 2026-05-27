// ignore_for_file: format-comment
// Required: Existing comments use generated or domain-specific formatting.
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tools/calculator_tool.dart';
import 'package:collection/collection.dart';

/// Service for managing app-defined AI tools with context-aware resolution.
///
/// This service provides hardcoded tool definitions and handles the resolution
/// of tool availability based on conversation and workspace preferences.
/// The resolution priority is: conversation → workspace → app defaults.
class ToolService {
  /// Hardcoded list of all available tools in the app
  static const List<UserToolEntity<Object, Object, Object>> availableTools = [
    CalculatorTool(),
  ];

  static List<UserToolType> getTypes({List<UserToolType>? without}) {
    var types = availableTools.map((e) => e.type);
    if (without != null && without.isNotEmpty) {
      types = types.where((element) => !without.contains(element));
    }
    return types.toList();
  }

  static List<UserToolEntity<Object, Object, Object>> getTools({
    List<UserToolType>? without,
    List<UserToolType>? only,
  }) {
    Iterable<UserToolEntity<Object, Object, Object>> types = availableTools;
    if (without != null && without.isNotEmpty) {
      types = types.where((element) => !without.contains(element.type));
    }
    if (only != null) {
      types = types.where((element) => only.contains(element.type));
    }
    return types.toList();
  }

  static UserToolEntity<Object, Object, Object>? getTool(
    UserToolType toolType,
  ) {
    return availableTools.firstWhereOrNull(
      (element) => element.type == toolType,
    );
  }

  static UserToolType getType(UserToolEntity<Object, Object, Object> tool) =>
      tool.type;
  static bool hasType(UserToolType type) =>
      availableTools.any((tool) => tool.type == type);
  static bool hasTypeString(String type) =>
      availableTools.any((tool) => tool.type.value == type);
}
