import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

class AppInputBase extends HookConsumerWidget {
  const AppInputBase({
    required this.labelLocaleKey,
    required this.placeholderLocaleKey,
    required this.initialValue,
    required this.onChanged,
    super.key,
    this.hintLocaleKey,
    this.obscureText = false,
  });

  final ProviderListenable<String> initialValue;
  final ProviderListenable<void Function(String)?> onChanged;
  final String labelLocaleKey;
  final String placeholderLocaleKey;
  final String? hintLocaleKey;
  final bool obscureText;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController(
      text: ref.watch(initialValue),
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
