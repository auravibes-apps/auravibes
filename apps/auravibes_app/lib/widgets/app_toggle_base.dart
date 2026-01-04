import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

class AppToggleBase extends ConsumerWidget {
  const AppToggleBase({
    required this.labelLocaleKey,
    required this.hintLocaleKey,
    required this.initialValue,
    required this.onChanged,
    super.key,
  });

  final ProviderListenable<bool> initialValue;
  // ignore: avoid_positional_boolean_parameters
  final ProviderListenable<void Function(bool)?> onChanged;
  final String labelLocaleKey;
  final String hintLocaleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(initialValue);
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
