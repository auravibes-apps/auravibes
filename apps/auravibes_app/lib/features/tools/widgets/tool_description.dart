import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/services/tools/user_tools_entity.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:flutter/material.dart';

class ToolDescriptionWidget extends StatelessWidget {
  const ToolDescriptionWidget({required this.toolType, super.key});
  final UserToolType toolType;

  @override
  Widget build(BuildContext context) {
    return TextLocale(switch (toolType) {
      UserToolType.calculator => LocaleKeys.tools_names_calculator_description,
    });
  }
}
