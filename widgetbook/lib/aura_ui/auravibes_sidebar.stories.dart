import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_sidebar.stories.bridge.g.dart';
part 'auravibes_sidebar.stories.g.dart';

const _sidebarWidth = 360.0;
const _sidebarHeight = 640.0;
const _maxSidebarIndex = 2;

class const _SidebarInput({
  required final bool expanded,
  required final int selectedIndex,
});

int _clampSidebarIndex(int index) {
  if (index < 0) return 0;

  return index > _maxSidebarIndex ? _maxSidebarIndex : index;
}

const _component = ComponentMeta(name: 'AuraSidebar');
const _meta = Meta(SidebarDemo.new, argsType: _SidebarInput.new);

final _Defaults _sidebarDefaults = _Defaults(
  builder: (context, args) =>
      SidebarDemo(expanded: args.expanded, selectedIndex: args.selectedIndex),
);

abstract final class _StorybookDefinitions {
  static final $Sidebar = _Story(
    name: 'Sidebar',
    setup: (context, child, args) =>
        SizedBox(width: _sidebarWidth, height: _sidebarHeight, child: child),
    args: _Args(
      expanded: BoolArg(true, name: 'Expanded'),
      selectedIndex: IntArg(
        0,
        name: 'Selected Index',
        style: const SliderIntArgStyle(min: 0, max: 2, divisions: 2),
      ),
    ),
    scenarios: [
      _Scenario(
        name: 'Compact Phone',
        modes: [ViewportMode(StoryHelpers.compactPhoneViewport)],
      ),
      _Scenario(
        name: 'Tablet',
        modes: [ViewportMode(StoryHelpers.tabletViewport)],
      ),
      _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(.rtl)]),
      _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
      _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
    ],
  );
}

/// Demonstrates expanded and compact directional navigation sidebars.
class const SidebarDemo({
  required final bool expanded,
  required final int selectedIndex,
  super.key,
}) extends StatefulWidget {
  @override
  State<SidebarDemo> createState() => _SidebarDemoState();
}

class _SidebarDemoState extends State<SidebarDemo> {
  static const _navigationItems = [
    AuraNavigationData(
      icon: Icon(Icons.home),
      label: Text('Home'),
      semanticLabel: 'Home navigation',
    ),
    AuraNavigationData(
      icon: Icon(Icons.folder),
      label: Text('Projects'),
      semanticLabel: 'Projects navigation',
    ),
    AuraNavigationData(
      icon: Icon(Icons.settings),
      label: Text('Settings'),
      semanticLabel: 'Settings navigation',
    ),
  ];
  static const _header = Padding(
    padding: EdgeInsets.all(16),
    child: AuraText(child: Text('Navigation')),
  );
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = _clampSidebarIndex(widget.selectedIndex);
  }

  @override
  void didUpdateWidget(covariant SidebarDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.selectedIndex != widget.selectedIndex) {
      _selectedIndex = _clampSidebarIndex(widget.selectedIndex);
    }
  }

  @override
  Widget build(BuildContext context) => AuraSidebar(
    navigationItems: _navigationItems,
    onNavigationTap: _select,
    isExpanded: widget.expanded,
    selectedIndex: _selectedIndex,
    header: _header,
  );

  void _select(int index) => setState(() => _selectedIndex = index);
}
