import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/aura_ui/story_helpers.dart';

part 'auravibes_sidebar.stories.g.dart';

class _SidebarInput {
  const _SidebarInput({required this.expanded, required this.selectedIndex});

  final bool expanded;
  final int selectedIndex;
}

int _clampSidebarIndex(int index) {
  if (index < 0) return 0;

  return index > 2 ? 2 : index;
}

const component = ComponentMeta(name: 'AuraSidebar');
const meta = Meta(SidebarDemo.new, argsType: _SidebarInput.new);

final _Defaults sidebarDefaults = _Defaults(
  builder: (context, args) =>
      SidebarDemo(expanded: args.expanded, selectedIndex: args.selectedIndex),
);

final $Sidebar = _Story(
  name: 'Sidebar',
  setup: (context, child, args) =>
      SizedBox(width: 360, height: 640, child: child),
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
      modes: [ViewportMode(compactPhoneViewport)],
    ),
    _Scenario(name: 'Tablet', modes: [ViewportMode(tabletViewport)]),
    _Scenario(name: 'RTL', modes: [AuraDirectionalityMode(TextDirection.rtl)]),
    _Scenario(name: 'Arabic', modes: [AuraArabicLocaleMode()]),
    _Scenario(name: 'Large Text', modes: [TextScaleMode(2)]),
  ],
);

/// Demonstrates expanded and compact directional navigation sidebars.
class SidebarDemo extends StatefulWidget {
  const SidebarDemo({
    required this.expanded,
    required this.selectedIndex,
    super.key,
  });

  final bool expanded;
  final int selectedIndex;

  @override
  State<SidebarDemo> createState() => _SidebarDemoState();
}

class _SidebarDemoState extends State<SidebarDemo> {
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
  Widget build(BuildContext context) {
    return AuraSidebar(
      navigationItems: const [
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
      ],
      onNavigationTap: (index) => setState(() => _selectedIndex = index),
      isExpanded: widget.expanded,
      selectedIndex: _selectedIndex,
      header: const Padding(
        padding: EdgeInsets.all(16),
        child: AuraText(child: Text('Navigation')),
      ),
    );
  }
}
