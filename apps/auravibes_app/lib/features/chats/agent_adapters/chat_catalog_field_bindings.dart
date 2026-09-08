import 'package:auravibes_app/features/chats/widgets/chat_a2ui_form_scope.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/widgets.dart';
import 'package:genui/genui.dart';

String chatCatalogFieldPath(Object? reference, String fallback) =>
    switch (reference) {
      {'path': final String path} => path,
      _ => fallback,
    };

void updateChatCatalogField(
  CatalogItemContext context,
  String path,
  Object? value,
) {
  ChatA2uiFormScope.markTouched(context.buildContext, path);
  context.dataContext.update(DataPath(path), value);
}

Widget scopeChatCatalogField(Map<String, Object?> data, Widget child) {
  if (data['disabled'] == true) {
    return AuraInteractionScope(
      policy: const AuraInteractionPolicy.disabled(),
      child: child,
    );
  }
  if (data['readOnly'] == true) {
    return AuraInteractionScope(
      policy: const AuraInteractionPolicy.readOnly(),
      child: child,
    );
  }

  return child;
}
