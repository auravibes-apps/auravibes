// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/knobs/selector.dart';

final List<KnobSelector<IconData>> _selectors = [
  const .new(value: Icons.add, label: 'Add'),
  const .new(value: Icons.edit, label: 'Edit'),
  const .new(value: Icons.favorite, label: 'Favorite'),
  const .new(value: Icons.thumb_up, label: 'Thumb Up'),
  const .new(value: Icons.star, label: 'Star'),
  const .new(value: Icons.info, label: 'Info'),
  const .new(value: Icons.settings, label: 'Settings'),
  const .new(value: Icons.search, label: 'Search'),
  const .new(value: Icons.home, label: 'Home'),
  const .new(value: Icons.person, label: 'Person'),
  const .new(value: Icons.camera_alt, label: 'Camera'),
  const .new(value: Icons.phone, label: 'Phone'),
  const .new(value: Icons.map, label: 'Map'),
  const .new(value: Icons.lock, label: 'Lock'),
];

extension IconDataKnobBuilder on KnobsBuilder {
  IconData iconData({String label = 'Icon Data', IconData? initialValue}) =>
      selector(label: label, selectors: _selectors, initialValue: initialValue);

  IconData? iconDataOrNull({
    String label = 'Icon Data',
    IconData? initialValue,
  }) => selectorOrNull(
    label: label,
    selectors: _selectors,
    initialValue: initialValue,
  );
}
