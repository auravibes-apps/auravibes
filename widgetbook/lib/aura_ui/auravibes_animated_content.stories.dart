import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'auravibes_animated_content.stories.g.dart';

const meta = Meta(AuraAnimatedContent.new);

final $Example = _Story(
  name: 'AuraAnimatedContent',
  setup: (context, child, args) => SizedBox(width: 320, child: child),
  args: _Args(child: Arg.fixed(const _FadeDemo())),
);

class _FadeDemo extends StatefulWidget {
  const new();

  @override
  State<_FadeDemo> createState() => _FadeDemoState();
}

class _FadeDemoState extends State<_FadeDemo> {
  bool _alternate = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AuraAnimatedContent(
          child: Text(
            _alternate ? 'Updated content' : 'Initial content',
            key: ValueKey(_alternate),
          ),
        ),
        AuraButton(
          onPressed: () => setState(() => _alternate = !_alternate),
          child: const Text('Change content'),
        ),
      ],
    );
  }
}
