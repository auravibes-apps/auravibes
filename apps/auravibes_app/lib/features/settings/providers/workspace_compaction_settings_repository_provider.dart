// ignore_for_file: newline-before-return
// Required: Existing test and UI helpers keep compact return flow.
// ignore_for_file: prefer-correct-identifier-length
// Required: Existing short identifiers follow callback and pattern APIs.
// ignore_for_file: prefer-static-class
// Required: Existing helpers remain top-level for local feature use.
import 'package:auravibes_app/data/repositories/workspace_compaction_settings_repository_impl.dart';
import 'package:auravibes_app/domain/repositories/workspace_compaction_settings_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'workspace_compaction_settings_repository_provider.g.dart';

@Riverpod(keepAlive: true)
WorkspaceCompactionSettingsRepository workspaceCompactionSettingsRepository(
  Ref ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return WorkspaceCompactionSettingsRepositoryImpl(
    db.workspaceCompactionSettingsDao,
  );
}
