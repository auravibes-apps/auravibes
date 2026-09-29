import 'package:flutter/widgets.dart';

abstract final class BottomPadding {
  static double of(BuildContext context, {double minimum = 16}) {
    final viewPadding = MediaQuery.viewPaddingOf(context).bottom;

    return viewPadding > minimum ? viewPadding : minimum;
  }
}
