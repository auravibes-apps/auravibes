import 'package:flutter/widgets.dart';

class const StableUiSelector({
  required final String identifier,
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Semantics(
    key: ValueKey<String>(identifier),
    child: child,
    identifier: identifier,
  );
}
