import 'package:auravibes_app/domain/entities/api_model_entity.dart';

List<String> codexInputModalities(ApiModelEntity model) {
  if (model.family != 'gpt-codex-spark' && !model.id.contains('codex-spark')) {
    return model.modalitiesInput;
  }

  return [
    for (final modality in model.modalitiesInput)
      if (modality == 'text') modality,
  ];
}
