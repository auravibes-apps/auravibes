import 'package:auravibes_app/data/repositories/background_work_repository.dart';

class const RecoverInterruptedBackgroundWorkUseCase(
  final BackgroundWorkRepository _repository,
) {
  Future<void> call({required DateTime startedAt}) =>
      _repository.reconcileInterrupted(startedAt: startedAt);
}
