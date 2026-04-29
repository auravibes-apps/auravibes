import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Text Badge', type: AuraBadge)
Widget textBadgeUseCase(BuildContext context) {
  return AuraBadge.text(
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraBadgeVariant.values,
    ),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraBadgeSize.values,
    ),
    child: Text(context.knobs.string(label: 'text', initialValue: 'Badge')),
  );
}

@widgetbook.UseCase(name: 'Count Badge', type: AuraBadge)
Widget countBadgeUseCase(BuildContext context) {
  return AuraBadge.count(
    count: context.knobs.int.input(label: 'count', initialValue: 5),
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraBadgeVariant.values,
    ),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraBadgeSize.values,
    ),
  );
}

@widgetbook.UseCase(name: 'Dot Badge', type: AuraBadge)
Widget dotBadgeUseCase(BuildContext context) {
  return AuraBadge.dot(
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraBadgeVariant.values,
    ),
  );
}

@widgetbook.UseCase(name: 'Custom Content Badge', type: AuraBadge)
Widget customContentBadgeUseCase(BuildContext context) {
  return AuraBadge(
    variant: context.knobs.object.dropdown(
      label: 'variant',
      options: AuraBadgeVariant.values,
    ),
    size: context.knobs.object.dropdown(
      label: 'size',
      options: AuraBadgeSize.values,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, size: 16, color: Colors.white),
        SizedBox(width: 4),
        Text('Premium', style: TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
