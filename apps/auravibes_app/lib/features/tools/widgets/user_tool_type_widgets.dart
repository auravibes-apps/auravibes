import 'package:auravibes_app/domain/entities/tool_permission_mode.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/native_tool_type.dart';
import 'package:auravibes_app/services/tools/user_tool_type.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:material_ui/material_ui.dart';

extension UserToolTypeWidgets on UserToolType {
  Widget getIconWidget() {
    return switch (this) {
      .calculator => const Icon(Icons.calculate),
    };
  }

  Widget getNameWidget() {
    return TextLocale(switch (this) {
      .calculator => LocaleKeys.tools_names_calculator_name,
    });
  }

  Widget getDescriptionWidget() {
    return TextLocale(switch (this) {
      .calculator => LocaleKeys.tools_names_calculator_description,
    });
  }
}

extension NativeToolTypeWidgets on NativeToolType {
  Widget getIconWidget() {
    return switch (this) {
      .url => const Icon(Icons.link),
    };
  }

  Widget getNameWidget() {
    return TextLocale(switch (this) {
      .url => LocaleKeys.tools_names_url_name,
    });
  }

  Widget getDescriptionWidget() {
    return TextLocale(switch (this) {
      .url => LocaleKeys.tools_names_url_description,
    });
  }
}

extension WorkspaceToolEntityWidgets on WorkspaceToolEntity {
  String localizedName(BuildContext context) {
    final builtIn = buildInType;
    if (builtIn != null) {
      return switch (builtIn) {
        .calculator => LocaleKeys.tools_names_calculator_name.tr(
          context: context,
        ),
      };
    }
    final native = nativeType;
    if (native != null) {
      return switch (native) {
        .url => LocaleKeys.tools_names_url_name.tr(context: context),
      };
    }

    return ToolNameFormatter.formatSkillDisplayName(toolId) ?? toolId;
  }

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

    final skillDisplayName = ToolNameFormatter.formatSkillDisplayName(toolId);
    if (skillDisplayName != null) {
      return Text(skillDisplayName);
    }

    return Text(toolId);
  }

  Widget getDescriptionWidget() {
    final description = this.description;
    if (description != null && description.isNotEmpty) {
      return Text(description);
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
