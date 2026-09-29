import 'dart:async';

import 'package:auravibes_ui/ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:package_info_plus/package_info_plus.dart';

class const AppVersionIndicator({super.key}) extends StatefulWidget {
  @override
  State<AppVersionIndicator> createState() => _AppVersionIndicatorState();
}

class _AppVersionIndicatorState extends State<AppVersionIndicator> {
  final Future<PackageInfo> _packageInfo = PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) => FutureBuilder<PackageInfo>(
    future: _packageInfo,
    builder: (context, snapshot) {
      final info = snapshot.data;
      if (info == null) return const SizedBox.shrink();

      final build = info.buildNumber.isEmpty ? '' : ' (${info.buildNumber})';

      return Text(
        '${info.appName} ${info.version}$build',
        style: .new(
          color: context.auraColors.onSurfaceVariant,
          fontSize: 12,
          fontWeight: .w500,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
    },
  );
}
