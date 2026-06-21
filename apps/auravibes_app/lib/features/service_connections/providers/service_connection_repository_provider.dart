import 'package:auravibes_app/data/repositories/service_connection_repository.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:auravibes_app/services/encryption_service.dart';
import 'package:riverpod/riverpod.dart';

final serviceConnectionRepositoryProvider =
    Provider<ServiceConnectionRepository>((ref) {
      return ServiceConnectionRepository(
        ref.watch(appDatabaseProvider),
        ref.watch(encryptionServiceProvider),
      );
    });
