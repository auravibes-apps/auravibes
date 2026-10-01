import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_health.dart';
import 'package:auravibes_app/features/cloud_accounts/models/cloud_account_key.dart';
import 'package:auravibes_app/features/cloud_accounts/providers/serverpod_client_provider.dart';
import 'package:auravibes_app/features/cloud_accounts/usecases/check_cloud_account_usecase.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cloud_account_health_provider.g.dart';

@Riverpod(keepAlive: true)
CheckCloudAccountUsecase checkCloudAccountUsecase(Ref ref) =>
    CheckCloudAccountUsecase(check: (key) => _checkCloudAccount(ref, key));

Future<String?> _checkCloudAccount(Ref ref, CloudAccountKey key) async {
  final client = await ref.read(serverpodClientForAccountProvider(key).future);
  final account = await client?.account.currentUser();

  return account?.userId;
}

@Riverpod(keepAlive: true)
Future<CloudAccountHealth> cloudAccountHealth(Ref ref, CloudAccountKey key) =>
    ref.watch(checkCloudAccountUsecaseProvider).call(key);
