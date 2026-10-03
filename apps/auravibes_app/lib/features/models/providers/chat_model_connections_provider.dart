import 'package:auravibes_app/domain/entities/model_connection_entity.dart';
import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_model_connections_provider.g.dart';

@riverpod
Stream<List<ModelConnectionEntity>> chatModelConnections(
  Ref ref,
  String workspaceId,
) async* {
  final store = await ref.watch(
    modelConnectionStoreProvider(workspaceId).future,
  );
  yield* store.watchModelConnections(.new(workspaces: [workspaceId]));
}
