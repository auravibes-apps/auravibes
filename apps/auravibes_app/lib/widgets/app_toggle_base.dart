// Required: Existing test and UI helpers keep compact return flow.
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
  // ignore: avoid_positional_boolean_parameters - Required by toggle callback shape.
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
            children: [
              AuraText(
                child: TextLocale(labelLocaleKey),
              ),
              AuraText(
                child: TextLocale(hintLocaleKey),
                style: AuraTextStyle.bodySmall,
                color: AuraColorVariant.onSurfaceVariant,
              ),
            ],
            spacing: AuraSpacing.none,
            crossAxisAlignment: CrossAxisAlignment.start,
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
