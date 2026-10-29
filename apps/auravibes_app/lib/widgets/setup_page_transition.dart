import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const SetupPageTransition({
  required final Widget child,
  final bool reverse = false,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    child: child,
    duration:
        MediaQuery.disableAnimationsOf(context) ||
            MediaQuery.accessibleNavigationOf(context)
        ? Duration.zero
        : context.auraTheme.animation.slow,
    switchInCurve: Curves.easeOutCubic,
    switchOutCurve: Curves.easeOutCubic,
    transitionBuilder: _transition,
    layoutBuilder: _layout,
  );

  static Widget _layout(Widget? current, List<Widget> previous) =>
      Stack(fit: .expand, children: [...previous, ?current]);

  Widget _transition(Widget page, Animation<double> animation) {
    final incoming = page.key == child.key;
    final direction = reverse ? -1.0 : 1.0;

    return _SetupPageSlide(
      page: page,
      animation: animation,
      incoming: incoming,
      direction: direction,
    );
  }
}

class _SetupPageSlide extends StatelessWidget {
  new({
    required Widget page,
    required Animation<double> animation,
    required bool incoming,
    required double direction,
  }) : _child = IgnorePointer(
         ignoring: !incoming,
         child: ExcludeSemantics(
           excluding: !incoming,
           child: ExcludeFocus(
             excluding: !incoming,
             child: SlideTransition(
               position: Tween<Offset>(
                 begin: Offset(incoming ? direction : -direction, 0),
                 end: Offset.zero,
               ).animate(animation),
               child: page,
             ),
           ),
         ),
       );
  final Widget _child;
  @override
  Widget build(BuildContext context) => _child;
}
