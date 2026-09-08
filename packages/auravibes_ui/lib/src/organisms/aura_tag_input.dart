import 'package:auravibes_ui/src/atoms/aura_interaction_scope.dart';
import 'package:auravibes_ui/src/atoms/aura_text.dart';
import 'package:auravibes_ui/src/molecules/aura_badge.dart';
import 'package:auravibes_ui/src/tokens/aura_theme.dart';
import 'package:flutter/material.dart';

/// A controlled set of short text tags.
class AuraTagInput extends StatefulWidget {
  /// Creates a tag input.
  const new({
    required this.value,
    required this.onChanged,
    required this.removeLabel,
    super.key,
    this.label,
    this.placeholder,
    this.maxTags,
  });

  /// Current tags.
  final List<String> value;

  /// Called with the next tag list.
  final ValueChanged<List<String>>? onChanged;

  /// Builds the accessible label for removing each tag.
  final String Function(String tag) removeLabel;

  /// Optional field label.
  final String? label;

  /// Optional empty-field hint.
  final String? placeholder;

  /// Optional selection cap.
  final int? maxTags;

  @override
  State<AuraTagInput> createState() => _AuraTagInputState();
}

class _AuraTagInputState extends State<AuraTagInput> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final enabled =
        AuraInteractionScope.of(context).allowsValueChanges &&
        widget.onChanged != null;
    final callback = widget.onChanged;
    void add(String raw) {
      final tag = raw.trim();
      if (!enabled ||
          callback == null ||
          tag.isEmpty ||
          widget.value.contains(tag)) {
        return;
      }
      if (widget.maxTags case final max? when widget.value.length >= max) {
        return;
      }
      callback([...widget.value, tag]);
      _controller.clear();
    }

    return Column(
      crossAxisAlignment: .start,
      spacing: context.auraTheme.spacing.sm,
      children: [
        if (widget.label case final value?)
          AuraText(child: Text(value), style: .bodySmall),
        Wrap(
          spacing: context.auraTheme.spacing.xs,
          children: [
            for (final tag in widget.value)
              AuraBadge.text(
                child: Row(
                  mainAxisSize: .min,
                  children: [
                    Text(tag),
                    IconButton(
                      onPressed: enabled && callback != null
                          ? () => callback(
                              widget.value
                                  .where((candidate) => candidate != tag)
                                  .toList(),
                            )
                          : null,
                      tooltip: widget.removeLabel(tag),
                      icon: const Icon(Icons.close, size: 16),
                    ),
                  ],
                ),
                semanticLabel: tag,
              ),
          ],
        ),
        TextField(
          controller: _controller,
          decoration: .new(hintText: widget.placeholder),
          onSubmitted: add,
          enabled: enabled,
        ),
      ],
    );
  }
}
