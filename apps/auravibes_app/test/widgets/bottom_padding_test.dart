import 'package:auravibes_app/widgets/bottom_padding.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the minimum when there is no system bottom inset', (
    tester,
  ) async {
    double? bottomPadding;
    double? smallerMinimum;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(),
        child: Builder(
          builder: (context) {
            bottomPadding = BottomPadding.of(context);
            smallerMinimum = BottomPadding.of(context, minimum: 8);

            return const SizedBox();
          },
        ),
      ),
    );

    expect(bottomPadding, 16);
    expect(smallerMinimum, 8);
  });

  testWidgets('uses a larger system bottom inset', (tester) async {
    double? bottomPadding;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(viewPadding: .only(bottom: 34)),
        child: Builder(
          builder: (context) {
            bottomPadding = BottomPadding.of(context);

            return const SizedBox();
          },
        ),
      ),
    );

    expect(bottomPadding, 34);
  });
}
