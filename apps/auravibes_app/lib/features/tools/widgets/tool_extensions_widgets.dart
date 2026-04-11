import 'package:auravibes_app/domain/entities/workspace_tool.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/native_tool_entity.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter/material.dart';

extension UserToolTypeWidgets on UserToolType {
  Widget getIconWidget() {
    return switch (this) {
      UserToolType.calculator => const Icon(Icons.calculate),
    };
  }

  Widget getNameWidget() {
    return TextLocale(
      switch (this) {
        UserToolType.calculator => LocaleKeys.tools_names_calculator_name,
      },
    );
  }

  Widget getDescriptionWidget() {
    return TextLocale(switch (this) {
      UserToolType.calculator => LocaleKeys.tools_names_calculator_description,
    });
  }
}

extension NativeToolTypeWidgets on NativeToolType {
  Widget getIconWidget() {
    return switch (this) {
      NativeToolType.url => const Icon(Icons.link),
    };
  }

  Widget getNameWidget() {
    return TextLocale(
      switch (this) {
        NativeToolType.url => LocaleKeys.tools_names_url_name,
      },
    );
  }

  Widget getDescriptionWidget() {
    return TextLocale(
      switch (this) {
        NativeToolType.url => LocaleKeys.tools_names_url_description,
      },
    );
  }
}

extension WorkspaceToolEntityWidgets on WorkspaceToolEntity {
  Widget getIconWidget() {
    final type = buildInType;
    final native = nativeType;

    if (type != null) {
      return type.getIconWidget();
    }

    if (native != null) {
      return native.getIconWidget();
    }

    return const Icon(Icons.extension);
  }

  Widget getNameWidget() {
    final type = buildInType;
    final native = nativeType;

    if (type != null) {
      return type.getNameWidget();
    }

    if (native != null) {
      return native.getNameWidget();
    }

    return Text(toolId);
  }

  Widget getDescriptionWidget() {
    if (hasDescription) {
      return Text(description!);
    }
    final type = buildInType;
    final native = nativeType;

    if (type != null) {
      return type.getDescriptionWidget();
    }

    if (native != null) {
      return native.getDescriptionWidget();
    }

    return const SizedBox.shrink();
  }
}
