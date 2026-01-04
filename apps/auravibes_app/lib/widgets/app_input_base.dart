import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// A reusable text input widget backed by Riverpod providers and localized UI strings.
///
/// This widget builds an [AuraInput] whose text is initialized from and kept in sync
/// with the given [value] provider. Any user changes are forwarded to the callback
/// exposed by the [onChanged] provider.
///
/// The `labelLocaleKey`, `placeholderLocaleKey`, and optional [hintLocaleKey] are
/// looked up via [TextLocale] to display localized label, placeholder, and hint
/// text. Set [obscureText] to `true` for sensitive inputs such as passwords.
class AppInputBase extends HookConsumerWidget {
  const AppInputBase({
    required this.labelLocaleKey,
    required this.placeholderLocaleKey,
    required this.value,
    required this.onChanged,
    super.key,
    this.hintLocaleKey,
    this.obscureText = false,
  });

  final ProviderListenable<String> value;
  final ProviderListenable<void Function(String)?> onChanged;
  final String labelLocaleKey;
  final String placeholderLocaleKey;
  final String? hintLocaleKey;
  final bool obscureText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(value),
    );
    return AuraInput(
      controller: controller,
      onChanged: ref.watch(onChanged),
      label: TextLocale(
        labelLocaleKey,
      ),
      placeholder: TextLocale(
        placeholderLocaleKey,
      ),
      hint: hintLocaleKey != null
          ? TextLocale(
              hintLocaleKey!,
            )
          : null,
      obscureText: obscureText,
    );
  }
}
