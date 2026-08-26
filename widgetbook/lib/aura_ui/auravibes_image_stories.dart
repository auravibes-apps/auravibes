// Required: Widgetbook stories use fixed example sizes.
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Basic Image', type: AuraImage)
Widget basicImageUseCase(BuildContext context) {
  return SizedBox(
    width: 320,
    height: 200,
    child: AuraImage(
      url: context.knobs.string(
        label: 'URL',
        initialValue: 'https://picsum.photos/seed/aura-image/320/200',
      ),
      fit: context.knobs.object.dropdown(
        label: 'Fit',
        options: BoxFit.values,
        labelBuilder: (value) => value.name,
      ),
      semanticLabel: context.knobs.stringOrNull(label: 'Semantic Label'),
    ),
  );
}
