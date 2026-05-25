import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;
import 'package:widgetbook_workspace/knobs/icons.dart';

@widgetbook.UseCase(name: 'Basic Icons', type: AuraIcon)
Widget basicIconsUseCase(BuildContext context) {
  return AuraIcon(
    context.knobs.iconData(),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraIconSize.values,
      labelBuilder: (value) => value.name,
    ),
  );
}

@widgetbook.UseCase(name: 'Icon Button Basic', type: AuraIconButton)
Widget iconButtonBasicUseCase(BuildContext context) {
  return AuraIconButton(
    icon: context.knobs.iconData(),
    onPressed: () {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Icon button pressed!')));
    },
    disabled: context.knobs.boolean(label: 'Disabled', initialValue: false),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraIconSize.values,
      labelBuilder: (value) => value.name,
    ),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraIconButtonVariant.values,
      labelBuilder: (value) => value.name,
    ),
    tooltip: context.knobs.string(
      label: 'Tooltip',
      initialValue: 'Add to favorites',
    ),
  );
}
