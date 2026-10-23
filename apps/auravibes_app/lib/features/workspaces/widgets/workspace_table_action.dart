import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:material_ui/material_ui.dart';

typedef WorkspaceTableAction = ({
  AsyncValue<void> state,
  Future<void> Function(Future<void> Function()) run,
});

extension WorkspaceTableActionState on WorkspaceTableAction {
  bool get pending => state.isLoading;
  Object? get error => switch (state) {
    AsyncError(:final error) => error,
    _ => null,
  };
}

abstract final class WorkspaceTableActions {
  static final _logger = Logger('workspace_table_action');

  static WorkspaceTableAction use(BuildContext context) {
    final state = useState<AsyncValue<void>>(const AsyncData(null));
    return (state: state.value, run: (action) => _run(context, state, action));
  }

  static Future<void> _run(
    BuildContext context,
    ValueNotifier<AsyncValue<void>> state,
    Future<void> Function() action,
  ) async {
    if (state.value.isLoading) return;
    state.value = const AsyncLoading();
    final result = await AsyncValue.guard(action);
    _complete(context, state, result);
  }

  static void _complete(
    BuildContext context,
    ValueNotifier<AsyncValue<void>> state,
    AsyncValue<void> result,
  ) {
    _logFailure(result);
    if (context.mounted) state.value = result;
  }

  static void _logFailure(AsyncValue<void> result) {
    if (result case AsyncError(:final error, :final stackTrace)) {
      _logger.warning(
        'Table action failed: ${error.runtimeType}',
        null,
        stackTrace,
      );
    }
  }
}
