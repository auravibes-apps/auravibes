import 'package:auravibes_app/domain/entities/api_model_entity.dart';

abstract final class CodexInputModalities {
  static List<String> forModel(ApiModelEntity model) {
    if (model.family != 'gpt-codex-spark' &&
        !model.id.contains('codex-spark')) {
      return model.modalitiesInput;
    }

    return model.modalitiesInput
        .where((modality) => modality == 'text')
        .toList();
  }
}
