import 'package:auravibes_app/features/chats/agent_adapters/chat_catalog_field_bindings.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('field path accepts only string references', () {
    expect(chatCatalogFieldPath({'path': '/name'}, '/fallback'), '/name');
    for (final value in [
      null,
      '/literal',
      <String, Object?>{},
      {'path': 1},
    ]) {
      expect(chatCatalogFieldPath(value, '/fallback'), '/fallback');
    }
  });

  for (final disabled in [false, true]) {
    for (final readOnly in [false, true]) {
      test('field disabled=$disabled readOnly=$readOnly', () {
        const child = SizedBox.shrink();
        final data = {'disabled': disabled, 'readOnly': readOnly};
        final result = scopeChatCatalogField(data, child);
        if (!disabled && !readOnly) {
          expect(result, same(child));

          return;
        }
        expect(
          result,
          isA<AuraInteractionScope>().having(
            (scope) => scope.policy,
            'policy',
            disabled
                ? const AuraInteractionPolicy.disabled()
                : const AuraInteractionPolicy.readOnly(),
          ),
        );
      });
    }
  }
}
