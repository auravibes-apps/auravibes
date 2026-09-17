import 'dart:async';

import 'package:auravibes_app/features/models/providers/model_store_providers.dart';
import 'package:auravibes_app/features/models/services/cloud_model_gateway.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'recent_model_selections_notifier.g.dart';

@riverpod
class RecentModelSelectionsNotifier extends _$RecentModelSelectionsNotifier {
  Future<void> _writeQueue = Future<void>.value();

  @override
  Future<List<String>> build(String workspaceId) async {
    final cloud = await ref.watch(
      cloudModelGatewayForWorkspaceProvider(workspaceId).future,
    );
    if (cloud != null) return await cloud.listRecentModelSelections();

    return await ref
        .watch(appDatabaseProvider)
        .recentModelSelectionsDao
        .getSelectionIds(workspaceId);
  }

  Future<void> record(String selectionId) {
    if (selectionId.isEmpty) return Future<void>.value();

    final previousWrite = _writeQueue;
    final completion = Completer<void>();
    final keepAlive = ref.keepAlive();
    _writeQueue = completion.future;

    return _recordAfter(
      previousWrite,
      completion,
      selectionId,
    ).whenComplete(keepAlive.close);
  }

  Future<void> _recordAfter(
    Future<void> previousWrite,
    Completer<void> completion,
    String selectionId,
  ) async {
    try {
      await previousWrite;
      final cloud = await ref.read(
        cloudModelGatewayForWorkspaceProvider(workspaceId).future,
      );
      if (cloud == null) {
        await ref
            .read(appDatabaseProvider)
            .recentModelSelectionsDao
            .recordSelection(workspaceId, selectionId);
      } else {
        await cloud.recordRecentModelSelection(selectionId);
      }
      ref.invalidateSelf();
    } finally {
      completion.complete();
    }
  }
}
