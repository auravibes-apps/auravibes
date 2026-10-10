import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_engine/auravibes_engine.dart'
    show callSkillToolName, normalizeToolCallUserFacingDescription;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

typedef SkillToolCallTarget = ({String skillSlug, String toolSlug});

abstract final class SkillToolCallDisplay {
  static SkillToolCallTarget? parseTarget(MessageToolCallEntity toolCall) {
    if (toolCall.name != callSkillToolName) return null;

    return _targetFromArguments(toolCall.argumentsRaw);
  }

  static String displayName({
    required BuildContext context,
    required SkillToolCallDisplayTitles? titles,
    required SkillToolCallTarget target,
  }) {
    final skillTitle = _localizedTitle(
      context,
      titles?.skillTitleKey,
      titles?.skillTitle ?? target.skillSlug.toHumanReadable(),
    );
    final toolTitle = _localizedTitle(
      context,
      titles?.toolTitleKey,
      titles?.toolTitle ?? target.toolSlug.toHumanReadable(),
    );

    return '$skillTitle / $toolTitle';
  }

  static String? description({
    required BuildContext context,
    required SkillToolCallDisplayTitles? titles,
    required String? userFacingDescription,
  }) {
    final userFacing = normalizeToolCallUserFacingDescription(
      userFacingDescription,
    );
    if (userFacing != null) return userFacing;

    final saved = _localizedTitle(
      context,
      titles?.toolDescriptionKey,
      titles?.toolDescription ?? '',
    );

    return normalizeToolCallUserFacingDescription(saved);
  }

  static SkillToolCallTarget? _targetFromArguments(String argumentsRaw) {
    try {
      final decoded = jsonDecode(argumentsRaw);
      if (decoded case {
        'skill': final String skillSlug,
        'tool': final String toolSlug,
      }) {
        return _validatedTarget(skillSlug, toolSlug);
      }
    } on FormatException {
      return null;
    }

    return null;
  }

  static SkillToolCallTarget? _validatedTarget(
    String skillSlug,
    String toolSlug,
  ) {
    final normalizedSkillSlug = skillSlug.trim();
    final normalizedToolSlug = toolSlug.trim();
    if (normalizedSkillSlug.isEmpty || normalizedToolSlug.isEmpty) {
      return null;
    }

    final compositeToolName = [
      'skill',
      'app',
      normalizedSkillSlug,
      normalizedToolSlug,
    ].join('__');
    if (ToolNameFormatter.parse(compositeToolName) == null) return null;

    return (skillSlug: normalizedSkillSlug, toolSlug: normalizedToolSlug);
  }

  static String _localizedTitle(
    BuildContext context,
    String? titleKey,
    String fallback,
  ) => titleKey?.tr(context: context) ?? fallback;
}
