import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// A reusable base widget for a provider-driven toggle/switch with text.
///
/// This widget listens to a [ProviderListenable<bool>] for the current
/// switch value and an optional [ProviderListenable<void Function(bool)?>]
/// for the `onChanged` callback. It displays a localized label and hint
/// using [TextLocale] with the provided [labelLocaleKey] and
/// [hintLocaleKey].
class AppToggleBase extends ConsumerWidget {
  const AppToggleBase({
    required this.labelLocaleKey,
    required this.hintLocaleKey,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final ProviderListenable<bool> value;
  // ignore: avoid_positional_boolean_parameters
  final ProviderListenable<void Function(bool)?> onChanged;
  final String labelLocaleKey;
  final String hintLocaleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(this.value);
    return Row(
      children: [
        Expanded(
          child: AuraColumn(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AuraSpacing.none,
            children: [
              AuraText(
                child: TextLocale(labelLocaleKey),
              ),
              AuraText(
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
                child: TextLocale(hintLocaleKey),
              ),
            ],
          ),
        ),
        AuraSwitch(
          value: value,
          onChanged: ref.watch(onChanged),
        ),
      ],
    );
  }
}
