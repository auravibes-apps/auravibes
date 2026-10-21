import 'package:auravibes_app/features/chats/providers/background_work_repository_provider.dart';
import 'package:auravibes_app/features/chats/usecases/recover_interrupted_background_work_use_case.dart';
import 'package:riverpod/riverpod.dart';

final recoverInterruptedBackgroundWorkUseCaseProvider =
    Provider<RecoverInterruptedBackgroundWorkUseCase>(
      (ref) => RecoverInterruptedBackgroundWorkUseCase(
        ref.watch(backgroundWorkRepositoryProvider),
      ),
    );
