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
    final data = _buildData(context);

    return _AuraTagInputView(
      spacing: context.auraTheme.spacing.sm,
      data: data,
      controller: _controller,
    );
  }

  _AuraTagInputData _buildData(BuildContext context) => _AuraTagInputData(
    value: widget.value,
    callback: widget.onChanged,
    enabled:
        AuraInteractionScope.of(context).allowsValueChanges &&
        widget.onChanged != null,
    label: widget.label,
    placeholder: widget.placeholder,
    maxTags: widget.maxTags,
    removeLabel: widget.removeLabel,
  );
}

class _AuraTagInputView extends StatelessWidget {
  const new({
    required this.spacing,
    required this.data,
    required this.controller,
  });

  final double spacing;
  final _AuraTagInputData data;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: .start,
    spacing: spacing,
    children: [
      _AuraTagInputLabel(label: data.label),
      _AuraTagList.fromData(data: data, spacing: context.auraTheme.spacing.xs),
      _AuraTagInputTextField(data: data, controller: controller),
    ],
  );
}

class _AuraTagInputTextField extends StatelessWidget {
  const new({required this.data, required this.controller});

  final _AuraTagInputData data;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    decoration: .new(hintText: data.placeholder),
    onSubmitted: (raw) =>
        _addTag(.new(raw: raw, data: data, controller: controller)),
    enabled: data.enabled,
  );
}

class _AuraTagInputLabel extends StatelessWidget {
  const new({required this.label});

  final String? label;

  @override
  Widget build(BuildContext context) => switch (label) {
    final value? => AuraText(child: Text(value), style: .bodySmall),
    null => const SizedBox.shrink(),
  };
}

class _AuraTagList extends StatelessWidget {
  const new({required this.spacing, required this.children});

  new fromData({required _AuraTagInputData data, required double spacing})
    : this(
        spacing: spacing,
        children: [
          for (final tag in data.value)
            _AuraTagChip.fromData(
              tag: tag,
              enabled: data.enabled,
              removeLabel: data.removeLabel,
              onRemove: data.callback == null
                  ? null
                  : () => data.callback?.call(
                      data.value
                          .where((candidate) => candidate != tag)
                          .toList(),
                    ),
            ),
        ],
      );

  final double spacing;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: spacing, children: children);
}

class _AuraTagChip extends StatelessWidget {
  const new({required this.child});

  new fromData({
    required String tag,
    required bool enabled,
    required String Function(String tag) removeLabel,
    required VoidCallback? onRemove,
  }) : this(
         child: AuraBadge.text(
           child: Row(
             mainAxisSize: .min,
             children: [
               Text(tag),
               IconButton(
                 onPressed: enabled ? onRemove : null,
                 tooltip: removeLabel(tag),
                 icon: const Icon(Icons.close, size: 16),
               ),
             ],
           ),
           semanticLabel: tag,
         ),
       );

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class _AuraTagInputData {
  const new({
    required this.value,
    required this.callback,
    required this.enabled,
    required this.label,
    required this.placeholder,
    required this.maxTags,
    required this.removeLabel,
  });

  final List<String> value;
  final ValueChanged<List<String>>? callback;
  final bool enabled;
  final String? label;
  final String? placeholder;
  final int? maxTags;
  final String Function(String tag) removeLabel;
}

class _AuraTagAddRequest {
  const new({required this.raw, required this.data, required this.controller});

  final String raw;
  final _AuraTagInputData data;
  final TextEditingController controller;
}

void _addTag(_AuraTagAddRequest request) {
  final tag = request.raw.trim();
  if (!_canAddTag(request, tag)) return;
  request.data.callback?.call([...request.data.value, tag]);
  request.controller.clear();
}

bool _canAddTag(_AuraTagAddRequest request, String tag) {
  if (!_isTagInputReady(request.data, tag)) return false;

  final maxTags = request.data.maxTags;

  return maxTags == null || request.data.value.length < maxTags;
}

bool _isTagInputReady(_AuraTagInputData data, String tag) =>
    data.enabled &&
    data.callback != null &&
    tag.isNotEmpty &&
    !data.value.contains(tag);
