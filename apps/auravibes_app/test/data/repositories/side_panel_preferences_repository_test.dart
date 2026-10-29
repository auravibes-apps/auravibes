import 'package:auravibes_app/data/repositories/side_panel_preferences_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('defaults to a closed panel at forty percent width', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = SidePanelPreferencesRepository(
      await SharedPreferences.getInstance(),
    );

    expect(
      preferences.widthPercent,
      SidePanelPreferencesRepository.defaultWidthPercent,
    );
    expect(preferences.isOpenFor('chat-one'), isFalse);
  });

  test('restores saved width percent and open state', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SidePanelPreferencesRepository(
      await SharedPreferences.getInstance(),
    );
    await store.saveWidthPercent(0.37);
    await store.saveIsOpen(conversationId: 'chat-one', isOpen: true);

    final restored = SidePanelPreferencesRepository(
      await SharedPreferences.getInstance(),
    );

    expect(restored.widthPercent, 0.37);
    expect(restored.isOpenFor('chat-one'), isTrue);
    expect(restored.isOpenFor('chat-two'), isFalse);

    await store.saveIsOpen(conversationId: 'chat-one', isOpen: false);
    expect(
      SidePanelPreferencesRepository(await SharedPreferences.getInstance())
          .isOpenFor('chat-one'),
      isFalse,
    );
  });

  test('ignores a stored width outside the percentage range', () async {
    SharedPreferences.setMockInitialValues({
      SidePanelPreferencesRepository.widthPercentKey: 1.2,
    });
    final preferences = SidePanelPreferencesRepository(
      await SharedPreferences.getInstance(),
    );

    expect(
      preferences.widthPercent,
      SidePanelPreferencesRepository.defaultWidthPercent,
    );
  });
}
