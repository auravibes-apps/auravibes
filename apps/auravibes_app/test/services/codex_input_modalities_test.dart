import 'package:auravibes_app/domain/entities/api_model_entity.dart';
import 'package:auravibes_app/services/codex_input_modalities.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps only text modalities for Codex Spark models', () {
    final result = CodexInputModalities.forModel(
      const ApiModelEntity(
        modelProvider: 'openai',
        id: 'gpt-5.3-codex-spark',
        name: 'Codex',
        limitContext: 128000,
        limitOutput: 4096,
        modalitiesInput: ['image', 'text', 'audio', 'text'],
        modalitiesOutput: ['text'],
      ),
    );

    expect(result, ['text', 'text']);
  });
}
