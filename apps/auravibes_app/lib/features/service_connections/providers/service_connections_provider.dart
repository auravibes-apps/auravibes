import 'package:auravibes_app/features/models/providers/model_connection_repositories_providers.dart';
import 'package:auravibes_app/features/service_connections/models/service_connection_list_item.dart';
import 'package:auravibes_app/features/service_connections/usecases/watch_service_connection_list_items_usecase.dart';
import 'package:auravibes_app/features/skills/providers/skill_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/misc.dart';

final StreamProviderFamily<List<ServiceConnectionListItem>, String>
serviceConnectionsProvider =
    StreamProvider.family<List<ServiceConnectionListItem>, String>((
      ref,
      workspaceId,
    ) {
      final usecase = WatchServiceConnectionListItemsUsecase(
        ref.watch(appDatabaseProvider),
        ref.watch(modelConnectionRepositoryProvider),
        ref.watch(
          skillCredentialDefinitionsRepositoryProvider,
        ),
        ref.watch(skillCredentialsRepositoryProvider),
        DateTime.now,
      );

      return usecase(workspaceId);
    });
