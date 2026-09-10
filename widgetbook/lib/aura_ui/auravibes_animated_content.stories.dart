import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_animated_content.stories.bridge.g.dart';
part 'auravibes_animated_content.stories.g.dart';

const _meta = Meta(AuraAnimatedContent.new);

abstract final class _StorybookDefinitions {
  static final $Example = _Story(
    name: 'AuraAnimatedContent',
    setup: (context, child, args) => SizedBox(width: 320, child: child),
    args: _Args(child: .fixed(const _FadeDemo())),
  );
}

class _FadeDemo extends StatefulWidget {
  const new();

  @override
  State<_FadeDemo> createState() => _FadeDemoState();
}

class _FadeDemoState extends State<_FadeDemo> {
  bool _alternate = false;

  @override
  Widget build(BuildContext context) =>
      _FadeDemoData(alternate: _alternate, onPressed: _toggle).content;

  void _toggle() => setState(() => _alternate = !_alternate);
}

class _FadeDemoData {
  new({required bool alternate, required VoidCallback onPressed})
    : content = Column(
        mainAxisSize: .min,
        children: [
          AuraAnimatedContent(
            child: Text(
              alternate ? 'Updated content' : 'Initial content',
              key: ValueKey(alternate),
            ),
          ),
          AuraButton(onPressed: onPressed, child: const Text('Change content')),
        ],
      );

  final Column content;
}
