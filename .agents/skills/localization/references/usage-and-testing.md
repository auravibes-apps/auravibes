# Locale keys, widgets, and tests

Read this file when you use generated keys, render localized text, or test localization behavior.

## Use generated keys

Import keys from `package:auravibes_app/i18n/locale_keys.dart`. The generator owns this file. Do not edit it by hand.

Use `TextLocale` for widget text when possible:

```dart
TextLocale(LocaleKeys.menu_home)
```

Pass positional values with `args`:

```dart
TextLocale(
  LocaleKeys.chats_screens_chat_conversation_queued_messages_count,
  args: [count.toString()],
)
```

Use `.tr()` when code needs a translated string instead of a widget. Import `easy_localization` for its extension methods. User-facing errors must use typed exceptions that carry localization keys.

## Widget tests

The app helper is `TestableApp` in `apps/auravibes_app/test/helpers/test_app.dart`. It wraps `EasyLocalization` and the app test providers. Existing tests import it with a relative path. Do not use `package:auravibes_app/test/helpers/test_app.dart` or call `testableApp()`.

This example assumes file path `apps/auravibes_app/test/widgets/localization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import '../helpers/test_app.dart';

void main() {
  testWidgets('renders Home in English', (tester) async {
    await tester.pumpWidget(
      const TestableApp(child: TextLocale(LocaleKeys.menu_home)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);
  });
}
```

For tests in another directory, change the relative import from that test file. Use a unit test for logic that does not need a widget tree. Assert localization keys in unit tests that do not resolve text.
