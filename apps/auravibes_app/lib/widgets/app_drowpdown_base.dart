import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:riverpod/misc.dart';

/// Widget for selecting the transport type
class AppDrowdownBase<T> extends HookConsumerWidget {
  const AppDrowdownBase({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AuraSpacing.xs,
      children: [
        AuraText(
          style: AuraTextStyle.bodySmall,
          color: AuraColorVariant.onSurfaceVariant,
          child: TextLocale(labelLocaleKey),
        ),
        AuraDropdownSelector<T>(
          value: ref.watch(value),
          onChanged: ref.watch(onChanged),
          options: options,
        ),
      ],
    );
  }
}
