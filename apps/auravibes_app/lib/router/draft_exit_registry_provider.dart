import 'package:auravibes_app/router/draft_exit_registry.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

export 'draft_exit_registry.dart';

part 'draft_exit_registry_provider.g.dart';

@Riverpod(keepAlive: true)
DraftExitRegistry draftExitRegistry(Ref ref) {
  final registry = DraftExitRegistry();
  final _ = ref.onDispose(registry.dispose);

  return registry;
}
