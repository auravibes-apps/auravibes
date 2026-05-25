import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// Generic provider-based dropdown selector widget for choosing a value
/// from a list of options.
class AppDropdownBase<T> extends HookConsumerWidget {
  const AppDropdownBase({
    required this.value,
    required this.onChanged,
    required this.options,
    required this.labelLocaleKey,
    super.key,
  });

  final ProviderListenable<T?> value;
  final ProviderListenable<void Function(T?)?> onChanged;
  final List<AuraDropdownOption<T>> options;
  final String labelLocaleKey;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      children: [
        AuraText(
          child: TextLocale(labelLocaleKey),
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
        ),
        AuraDropdownSelector<T>(
          options: options,
          value: ref.watch(value),
          onChanged: ref.watch(onChanged),
        ),
      ],
      spacing: AuraSpacing.xs,
      crossAxisAlignment: CrossAxisAlignment.start,
    );
  }
}
