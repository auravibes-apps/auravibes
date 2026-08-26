import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'AuraList', type: AuraList)
Widget auraListUseCase(BuildContext context) {
  final direction = context.knobs.object.dropdown(
    label: 'direction',
    options: Axis.values,
    initialOption: Axis.vertical,
    labelBuilder: (value) => value.name,
  );
  final alignment = context.knobs.object.dropdown(
    label: 'alignment',
    options: const [
      CrossAxisAlignment.start,
      CrossAxisAlignment.center,
      CrossAxisAlignment.end,
      CrossAxisAlignment.stretch,
    ],
    initialOption: CrossAxisAlignment.stretch,
    labelBuilder: (value) => value.name,
  );
  final itemCount = context.knobs.int.slider(
    label: 'item count',
    initialValue: 8,
    min: 0,
    max: 20,
  );

  return SizedBox(
    width: double.infinity,
    height: direction == Axis.vertical ? 320 : 140,
    child: AuraList(
      children: [
        for (var index = 0; index < itemCount; index++)
          SizedBox(
            width: direction == Axis.horizontal ? 160 : null,
            height: 72,
            child: AuraCard(child: Center(child: Text('Item ${index + 1}'))),
          ),
      ],
      direction: direction,
      alignment: alignment,
    ),
  );
}
