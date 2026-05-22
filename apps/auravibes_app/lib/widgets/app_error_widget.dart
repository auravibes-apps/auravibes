import 'package:auravibes_ui/ui.dart';
import 'package:flutter/material.dart';

class AppErrorWidget extends StatelessWidget {
  const AppErrorWidget({
    required this.error,
    required this.stackTrace,
    super.key,
  });
  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return AuraText(
      child: Text('Error loading models: $error'),
    );
  }
}
