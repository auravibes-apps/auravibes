import 'dart:convert';

import 'package:auravibes_app/domain/entities/message_tool_call_entity.dart';
import 'package:auravibes_app/features/chats/providers/tool_display_name_provider.dart';
import 'package:auravibes_app/utils/string_extensions.dart';
import 'package:auravibes_app/utils/tool_name_formatter.dart';
import 'package:auravibes_engine/auravibes_engine.dart' show callSkillToolName;
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/widgets.dart';

typedef SkillToolCallTarget = ({String skillSlug, String toolSlug});

final _titleSeparator = ' ${String.fromCharCode(0xB7)} ';

SkillToolCallTarget? parseSkillToolCallTarget(MessageToolCallEntity toolCall) {
  if (toolCall.name != callSkillToolName) return null;

  try {
    final decoded = jsonDecode(toolCall.argumentsRaw);
    if (decoded case {
      'skill': final String skillSlug,
      'tool': final String toolSlug,
    }) {
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
  } on FormatException {
    return null;
  }

  return null;
}

String skillToolCallDisplayName({
  required BuildContext context,
  required SkillToolCallDisplayTitles? titles,
  required SkillToolCallTarget target,
}) {
  if (titles == null) {
    return '${target.skillSlug.toHumanReadable()}$_titleSeparator'
        '${target.toolSlug.toHumanReadable()}';
  }

  final skillTitle =
      titles.skillTitleKey?.tr(context: context) ?? titles.skillTitle;
  final toolTitle =
      titles.toolTitleKey?.tr(context: context) ??
      titles.toolTitle ??
      target.toolSlug.toHumanReadable();

  return '$skillTitle$_titleSeparator$toolTitle';
}
