import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// Generic provider-based single-selection button group widget.
class AppGroupButtonSingleBase<T> extends HookConsumerWidget {
  const AppGroupButtonSingleBase({
    required this.value,
    required this.items,
    required this.onChanged,
    required this.labelLocaleKey,
    super.key,
  });

  final ProviderListenable<T?> value;
  final ProviderListenable<ValueChanged<T>> onChanged;
  final List<AuraButtonGroupItem<T>> items;
  final String labelLocaleKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuraColumn(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.xs,
      children: [
        AuraText(
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
          child: TextLocale(labelLocaleKey),
        ),
        AuraButtonGroup<T>.single(
          selectedValue: ref.watch(value),
          onChanged: ref.watch(onChanged),
          items: items,
        ),
      ],
    );
  }
}
