// Required: Existing settings sections keep callbacks local to the widget.
import 'package:auravibes_app/features/settings/notifiers/accent_hue.dart';
import 'package:auravibes_app/i18n/locale_keys.dart';
import 'package:auravibes_app/widgets/text_locale.dart';
import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Settings section that lets the user pick the app's accent hue.
///
/// The hue is persisted via [AccentHueNotifier]; the whole palette recomputes
/// from it through [AuraComputedColorScheme].
class const AccentColorSection({super.key}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hue =
        ref.watch(accentHueProvider).asData?.value ?? AccentHue.defaultValue;

    return _AccentColorCard(
      hue: hue,
      onTap: () => _showAccentDialog(context, ref, hue),
    );
  }

  Future<void> _showAccentDialog(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    // Ponytail: persist once on Save; live preview stays local to the dialog.
    var working = current;
    final shouldSave = await _confirmAccentColor(
      context: context,
      current: current,
      onChanged: (value) => working = value,
    );
    if (shouldSave != true) return;

    await ref.read(accentHueProvider.notifier).setHue(working);
  }
}

Future<bool?> _confirmAccentColor({
  required BuildContext context,
  required double current,
  required ValueChanged<double> onChanged,
}) => AuraDialogs.confirm(
  context: context,
  title: const TextLocale(LocaleKeys.settings_screen_accent_color_dialog_title),
  message: _HueDialog(hue: current, onChanged: onChanged),
  actions: const AuraConfirmDialogActions(
    confirmLabel: TextLocale(LocaleKeys.settings_screen_actions_save),
    cancelLabel: TextLocale(LocaleKeys.settings_screen_actions_cancel),
  ),
);

class const _AccentColorCard({
  required final double hue,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuraCard(
      child: AuraColumn(
        children: [
          const _AccentColorHeader(),
          _AccentColorTile(hue: hue, onTap: onTap),
        ],
        spacing: .none,
        crossAxisAlignment: .start,
      ),
    );
  }
}

class const _AccentColorHeader() extends StatelessWidget {
  static const _content = AuraColumn(
    children: [
      AuraText(
        child: TextLocale(LocaleKeys.settings_screen_accent_color_title),
        style: .heading6,
      ),
      AuraText(
        child: TextLocale(LocaleKeys.settings_screen_accent_color_subtitle),
        style: .bodySmall,
      ),
    ],
    spacing: .none,
    crossAxisAlignment: .start,
  );

  @override
  Widget build(BuildContext context) => _content;
}

class const _AccentColorTile({
  required final double hue,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AuraTile(
    child: const AuraText(
      child: TextLocale(LocaleKeys.settings_screen_accent_color_title),
      style: .bodyLarge,
    ),
    onTap: onTap,
    variant: .ghost,
    leading: const _AccentColorTileLeading(),
    trailing: _AccentColorTileTrailing(hue: hue),
  );
}

class const _AccentColorTileLeading() extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Icon(Icons.color_lens_outlined, color: context.auraColors.secondary);
}

class const _AccentColorTileTrailing({required final double hue})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: .min,
    children: [
      _HueSwatch(hue: hue),
      const SizedBox(width: 8),
      Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: context.auraColors.onSurfaceVariant,
      ),
    ],
  );
}

class const _HueDialog({
  required final double hue,
  required final ValueChanged<double> onChanged,
}) extends StatefulWidget {
  @override
  State<_HueDialog> createState() => _HueDialogState();
}

class _HueDialogState extends State<_HueDialog> {
  double _hue = 0;

  @override
  void initState() {
    super.initState();
    _hue = widget.hue;
  }

  @override
  Widget build(BuildContext context) => AuraColumn(
    children: [
      _HueSwatch(hue: _hue, size: 48),
      _HueSlider(hue: _hue, onChanged: _updateHue),
    ],
    crossAxisAlignment: .stretch,
  );

  void _updateHue(double value) {
    setState(() => _hue = value);
    widget.onChanged(value);
  }
}

class const _HueSwatch({required final double hue, final double size = 24})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final color = _primaryColorFor(context, hue);

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: context.auraColors.outlineVariant),
        shape: .circle,
      ),
      width: size,
      height: size,
    );
  }
}

class const _HueSlider({
  required final double hue,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      const _HueGradient(),
      _HueSliderControl(hue: hue, onChanged: onChanged),
    ],
  );
}

class const _HueGradient() extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(.circular(6)),
      gradient: LinearGradient(colors: _hueGradientColors(context)),
    ),
    height: 12,
  );
}

const _hueStops = [0.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0];

List<Color> _hueGradientColors(BuildContext context) =>
    _hueStops.map((hue) => _primaryColorFor(context, hue)).toList();

class const _HueSliderControl({
  required final double hue,
  required final ValueChanged<double> onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.auraColors;

    return SliderTheme(
      data: _sliderThemeData(colors),
      child: Slider(
        value: hue.clamp(0, AccentHue.maxValue),
        onChanged: onChanged,
        max: AccentHue.maxValue,
      ),
    );
  }

  SliderThemeData _sliderThemeData(AuraColorScheme colors) => .new(
    trackHeight: 0,
    activeTrackColor: Colors.transparent,
    inactiveTrackColor: Colors.transparent,
    thumbColor: colors.onSurface,
    overlayColor: colors.primary.withValues(alpha: 0.12),
  );
}

Color _primaryColorFor(BuildContext context, double hue) {
  final brightness = Theme.of(context).brightness == Brightness.dark
      ? AuraBrightness.dark
      : AuraBrightness.light;

  return AuraComputedColorScheme(
    primaryHue: hue,
    brightness: brightness,
  ).primary;
}
