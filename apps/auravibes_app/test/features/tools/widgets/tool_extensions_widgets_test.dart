// ignore_for_file: no-equal-arguments
// Required: Tests use repeated fixture values to assert equality semantics.
import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/features/tools/widgets/user_tool_type_widgets.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

WorkspaceToolEntity _entity({
  String id = 'tool-1',
  String toolId = 'calculator',
  String? description,
}) {
  return WorkspaceToolEntity(
    id: id,
    workspaceId: 'ws1',
    toolId: toolId,
    isEnabled: true,
    permissionMode: ToolPermissionMode.alwaysAsk,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026),
    description: description,
  );
}

void main() {
  group('UserToolTypeWidgets', () {
    test('getIconWidget returns Icon', () {
      final widget = UserToolType.calculator.getIconWidget();
      expect(widget, isA<Icon>());
    });

    test('getNameWidget returns TextLocale', () {
      final widget = UserToolType.calculator.getNameWidget();
      expect(widget, isA<TextLocale>());
    });

    test('getDescriptionWidget returns TextLocale', () {
      final widget = UserToolType.calculator.getDescriptionWidget();
      expect(widget, isA<TextLocale>());
    });
  });

  group('NativeToolTypeWidgets', () {
    test('getIconWidget returns Icon', () {
      final widget = NativeToolType.url.getIconWidget();
      expect(widget, isA<Icon>());
    });

    test('getNameWidget returns TextLocale', () {
      final widget = NativeToolType.url.getNameWidget();
      expect(widget, isA<TextLocale>());
    });

    test('getDescriptionWidget returns TextLocale', () {
      final widget = NativeToolType.url.getDescriptionWidget();
      expect(widget, isA<TextLocale>());
    });
  });

  group('WorkspaceToolEntityWidgets', () {
    test('getIconWidget returns built-in type icon for calculator', () {
      final widget = _entity().getIconWidget();
      expect(widget, isA<Icon>());
    });

    test('getIconWidget returns native type icon for url', () {
      final widget = _entity(toolId: 'url').getIconWidget();
      expect(widget, isA<Icon>());
    });

    test('getIconWidget returns fallback icon for unknown type', () {
      final widget = _entity(toolId: 'unknown_tool').getIconWidget();
      expect(widget, isA<Icon>());
    });

    test('getNameWidget returns built-in type name for calculator', () {
      final widget = _entity().getNameWidget();
      expect(widget, isA<TextLocale>());
    });

    test('getNameWidget returns native type name for url', () {
      final widget = _entity(toolId: 'url').getNameWidget();
      expect(widget, isA<TextLocale>());
    });

    test('getNameWidget returns toolId Text for unknown type', () {
      final widget = _entity(toolId: 'custom_mcp_tool').getNameWidget();
      expect(widget, isA<Text>());
    });

    test('getDescriptionWidget returns Text when description set', () {
      final widget = _entity(
        description: 'A calculator',
      ).getDescriptionWidget();
      expect(widget, isA<Text>());
    });

    test(
      'getDescriptionWidget returns built-in description for calculator',
      () {
        final widget = _entity().getDescriptionWidget();
        expect(widget, isA<TextLocale>());
      },
    );

    test('getDescriptionWidget returns native description for url', () {
      final widget = _entity(toolId: 'url').getDescriptionWidget();
      expect(widget, isA<TextLocale>());
    });

    test(
      'getDescriptionWidget returns SizedBox.shrink for unknown no-desc',
      () {
        final widget = _entity(toolId: 'unknown_tool').getDescriptionWidget();
        expect(widget, isA<SizedBox>());
      },
    );
  });
}
