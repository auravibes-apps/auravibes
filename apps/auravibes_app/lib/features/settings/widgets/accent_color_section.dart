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
class AccentColorSection extends ConsumerWidget {
  const AccentColorSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hue = ref.watch(accentHueProvider).asData?.value ?? defaultAccentHue;

    return AuraCard(
      child: AuraColumn(
        children: [
          const AuraText(
            child: TextLocale(LocaleKeys.settings_screen_accent_color_title),
            style: AuraTextStyle.heading6,
            color: AuraColorVariant.onSurface,
          ),
          const AuraText(
            child: TextLocale(
              LocaleKeys.settings_screen_accent_color_subtitle,
            ),
            style: AuraTextStyle.bodySmall,
            color: AuraColorVariant.onSurfaceVariant,
          ),
          AuraTile(
            child: const AuraText(
              child: TextLocale(
                LocaleKeys.settings_screen_accent_color_title,
              ),
              style: AuraTextStyle.bodyLarge,
            ),
            onTap: () => _showAccentDialog(context, ref, hue),
            variant: AuraTileVariant.ghost,
            leading: Icon(
              Icons.color_lens_outlined,
              color: context.auraColors.secondary,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HueSwatch(hue: hue),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: context.auraColors.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ],
        spacing: .none,
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }

  Future<void> _showAccentDialog(
    BuildContext context,
    WidgetRef ref,
    double current,
  ) async {
    // ponytail: persist once on Save; live preview stays local to the dialog.
    var working = current;
    final shouldSave = await showAuraConfirmDialog(
      context: context,
      title: const TextLocale(
        LocaleKeys.settings_screen_accent_color_dialog_title,
      ),
      message: StatefulBuilder(
        builder: (context, setState) {
          return AuraColumn(
            children: [
              _HueSwatch(hue: working, size: 48),
              _HueSlider(
                hue: working,
                onChanged: (v) => setState(() => working = v),
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.stretch,
          );
        },
      ),
      actions: const AuraConfirmDialogActions(
        confirmLabel: TextLocale(LocaleKeys.settings_screen_actions_save),
        cancelLabel: TextLocale(LocaleKeys.settings_screen_actions_cancel),
      ),
    );
    if (shouldSave != true) return;

    await ref.read(accentHueProvider.notifier).setHue(working);
  }
}

class _HueSwatch extends StatelessWidget {
  const _HueSwatch({required this.hue, this.size = 24});

  final double hue;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _primaryColorFor(context, hue);

    return Container(
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: context.auraColors.outlineVariant),
        shape: BoxShape.circle,
      ),
      width: size,
      height: size,
    );
  }
}

class _HueSlider extends StatelessWidget {
  const _HueSlider({required this.hue, required this.onChanged});

  final double hue;
  final ValueChanged<double> onChanged;

  static const _stops = [0.0, 60.0, 120.0, 180.0, 240.0, 300.0, 360.0];

  @override
  Widget build(BuildContext context) {
    final colors = _stops.map((h) => _primaryColorFor(context, h)).toList();

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(6)),
            gradient: LinearGradient(
              colors: colors,
            ),
          ),
          height: 12,
        ),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 0,
            activeTrackColor: Colors.transparent,
            inactiveTrackColor: Colors.transparent,
            thumbColor: context.auraColors.onSurface,
            overlayColor: context.auraColors.primary.withValues(alpha: 0.12),
          ),
          child: Slider(
            value: hue.clamp(0, 360),
            onChanged: onChanged,
            max: 360,
          ),
        ),
      ],
    );
  }
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
