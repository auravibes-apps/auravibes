import 'dart:async';

import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';

class const AppFilterSheetButton({
  required final int activeFilterCount,
  required final WidgetBuilder filtersBuilder,
  required final VoidCallback onClearFilters,
  super.key,
}) extends StatelessWidget {
  static const breakpoint = 600.0;

  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerEnd,
    child: AuraButton(
      onPressed: () => _showFilterSheet(context),
      child: _AppFilterSheetButtonLabel(activeFilterCount: activeFilterCount),
      key: const ValueKey('app_filter_sheet'),
      variant: .ghost,
      size: .small,
      identifier: 'app_filter_sheet',
    ),
  );

  void _showFilterSheet(BuildContext context) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        builder: (_) => _AppFilterSheet(
          filtersBuilder: filtersBuilder,
          onClearFilters: onClearFilters,
        ),
        isScrollControlled: true,
        useSafeArea: true,
      ),
    );
  }
}

class const _AppFilterSheetButtonLabel({required final int activeFilterCount})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      const AuraIcon(Icons.tune, size: .small),
      const SizedBox(width: 6),
      TextLocale(
        LocaleKeys.common_filters_count,
        args: [activeFilterCount.toString()],
      ),
    ],
  );
}

class const _AppFilterSheet({
  required final WidgetBuilder filtersBuilder,
  required final VoidCallback onClearFilters,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: .new(maxHeight: MediaQuery.sizeOf(context).height * 0.9),
    child: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _AppFilterSheetContents(
          filtersBuilder: filtersBuilder,
          onClearFilters: onClearFilters,
        ),
      ),
    ),
  );
}

class const _AppFilterSheetContents({
  required final WidgetBuilder filtersBuilder,
  required final VoidCallback onClearFilters,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: .min,
    children: [
      _AppFilterSheetHeader(onClearFilters: onClearFilters),
      Flexible(child: _AppFilterSheetFields(builder: filtersBuilder)),
    ],
  );
}

class const _AppFilterSheetHeader({required final VoidCallback onClearFilters})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: [
      const Expanded(
        child: AuraText(
          child: TextLocale(LocaleKeys.common_filters),
          style: .heading4,
        ),
      ),
      AuraButton(
        onPressed: onClearFilters,
        child: const TextLocale(LocaleKeys.common_clear_filters),
        variant: .ghost,
        size: .small,
      ),
    ],
  );
}

class const _AppFilterSheetFields({required final WidgetBuilder builder})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    child: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: builder(context),
    ),
  );
}
