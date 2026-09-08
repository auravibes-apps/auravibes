import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

Widget buildChatCatalogChildren(
  CatalogItemContext context,
  Object? children,
  Widget Function(List<Widget>) build, {
  Widget Function(String id, Widget child)? decorate,
}) => ComponentChildrenBuilder(
  childrenData: children,
  dataContext: context.dataContext,
  buildChild: context.buildChild,
  getComponent: context.getComponent,
  explicitListBuilder: (ids, buildChild, _, dataContext) => build([
    for (final id in ids)
      decorate?.call(id, buildChild(id, dataContext)) ??
          buildChild(id, dataContext),
  ]),
  templateListWidgetBuilder: (buildContext, data, componentId, binding) {
    final keys = switch (data) {
      List() => List.generate(data.length, (index) => '$index'),
      Map<Object?, Object?>() => data.keys.map((key) => '$key').toList(),
      _ => null,
    };
    if (keys == null) {
      return const SizedBox.shrink();
    }

    return build([
      for (final key in keys)
        KeyedSubtree(
          key: ValueKey(key),
          child: (decorate ?? (_, child) => child)(
            componentId,
            context.buildChild(
              componentId,
              context.dataContext.nested(DataPath('$binding/$key')),
            ),
          ),
        ),
    ]);
  },
);
