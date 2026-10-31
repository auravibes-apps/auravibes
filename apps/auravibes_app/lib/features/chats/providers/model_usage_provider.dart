import 'package:auravibes_app/data/repositories/model_usage_repository.dart';
import 'package:auravibes_app/domain/entities/model_usage_aggregation.dart';
import 'package:auravibes_app/domain/entities/model_usage_record.dart';
import 'package:auravibes_app/domain/entities/model_usage_totals.dart';
import 'package:auravibes_app/features/chats/usecases/record_model_usage_usecase.dart';
import 'package:auravibes_app/features/models/providers/api_model_repository_providers.dart';
import 'package:auravibes_app/providers/app_providers.dart';
import 'package:riverpod/misc.dart' show FutureProviderFamily;
import 'package:riverpod/riverpod.dart';

typedef ModelUsageConversationDetails = ({
  List<ModelUsageRecord> records,
  ModelUsageTotals totals,
});

final modelUsageRepositoryProvider = Provider<ModelUsageRepository>(
  (ref) => ModelUsageRepository(ref.watch(appDatabaseProvider)),
);

final FutureProviderFamily<List<ModelUsageRecord>, String>
modelUsageRecordsForConversationProvider = FutureProvider.autoDispose
    .family<List<ModelUsageRecord>, String>(
      (ref, conversationId) => ref
          .watch(modelUsageRepositoryProvider)
          .getRecordsForConversation(conversationId),
    );

final FutureProviderFamily<ModelUsageConversationDetails, String>
modelUsageDetailsForConversationProvider = FutureProvider.autoDispose
    .family<ModelUsageConversationDetails, String>((ref, conversationId) async {
      final records = await ref.watch(
        modelUsageRecordsForConversationProvider(conversationId).future,
      );
      final totals = ModelUsageAggregation.aggregate(records);

      return (records: records, totals: totals);
    });

final recordModelUsageUsecaseProvider = Provider<RecordModelUsageUsecase>(
  (ref) => RecordModelUsageUsecase(
    repository: ref.watch(modelUsageRepositoryProvider),
    getModel: (providerId, modelId) => ref
        .read(apiModelRepositoryProvider)
        .getModelByProviderAndModelId(providerId, modelId),
  ),
);
