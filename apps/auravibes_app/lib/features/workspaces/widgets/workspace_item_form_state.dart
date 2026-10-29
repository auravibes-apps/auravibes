import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:material_ui/material_ui.dart';

class const WorkspaceItemFormState(
  final TextEditingController name,
  final ValueNotifier<bool> pending,
  final ValueNotifier<Object?> error,
) {
  factory use({String name = ''}) => WorkspaceItemFormState(
    useTextEditingController(text: name),
    useState(false),
    useState(null),
  );

  Future<void> run(BuildContext context, Future<void> Function() action) async {
    if (pending.value) return;
    _start();
    try {
      await action();
    } on Object catch (failure) {
      _failed(failure, mounted: context.mounted);
    } finally {
      _finish(mounted: context.mounted);
    }
  }

  void _start() {
    pending.value = true;
    error.value = null;
  }

  void _failed(Object failure, {required bool mounted}) {
    if (mounted) error.value = failure;
  }

  void _finish({required bool mounted}) {
    if (mounted) pending.value = false;
  }
}
